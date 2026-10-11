"""Locked Nix configuration and non-privileged Sunshine firewall policy checks."""

import ipaddress
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
PORTS = {
    "tcp": (47984, 47989, 47990, 48010),
    "udp": (47998, 47999, 48000, 48002, 48010),
}


def apply_rules(rules, script):
    """Model our -I/-D operations, without running iptables or requiring root."""
    for line in script.splitlines():
        # Other modules add helpers/NAT setup to the same option; this model
        # is deliberately limited to our literal nixos-fw insert/delete rules.
        if not line.strip().startswith(("iptables -I nixos-fw ", "iptables -D nixos-fw ")):
            continue
        words = shlex.split(line)
        assert words[0] == "iptables" and words[2] == "nixos-fw", words
        if words[1] == "-I":
            assert words[3] == "1", words
            rules.insert(0, words[4:])
        elif words[1] == "-D":
            rules.remove(words[3:words.index("2>/dev/null")])
        else:
            raise AssertionError(words)


def verdict(rules, interface, source, protocol, port):
    for rule in rules:
        matches = True
        negate = False
        action = None
        index = 0
        while index < len(rule):
            token = rule[index]
            if token == "!":
                negate = True
                index += 1
                continue
            value = rule[index + 1]
            if token == "-i":
                condition = interface == value
            elif token == "-s":
                condition = ipaddress.ip_address(source) in ipaddress.ip_network(value)
            elif token == "-p":
                condition = protocol == value
            elif token == "--dports":
                condition = port in map(int, value.split(","))
            elif token == "-j":
                action = value
                condition = True
            elif token == "-m":
                assert value == "multiport"
                condition = True
            else:
                raise AssertionError(rule)
            matches = matches and (not condition if negate else condition)
            negate = False
            index += 2
        if matches:
            return action
    # Model Adam's pre-existing broad accept for ports 2000-65535.
    return "ACCEPT" if 2000 <= port <= 65535 else "DROP"


@unittest.skipUnless(shutil.which("nix"), "Nix is required to evaluate the configuration")
class RemoteDesktopTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = json.dumps(str(ROOT))
        expression = f"""
          let
            root = {root};
            load = host:
              (import (root + "/" + host + "/flake.nix")).outputs
                (builtins.getFlake ("git+file://" + root + "?dir=" + host)).inputs;
            server = (load "adam").nixosConfigurations.host.config;
            client = (load "michael").homeConfigurations.home.config;
          in {{
            inherit (server.services.sunshine) settings capSysAdmin applications;
            firewall = {{
              inherit (server.networking.firewall) enable backend extraCommands extraStopCommands;
            }};
            sessionCommand = server.services.greetd.settings.default_session.command;
            wantedBy = server.systemd.user.services.sunshine.wantedBy;
            clientPackages = map (package: package.name) client.home.packages;
          }}
        """
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
        cls.config = json.loads(result.stdout)

    def test_unprivileged_vpn_capture(self):
        settings = self.config["settings"]
        for key, expected in {
            "bind_address": "10.255.255.61",
            "address_family": "ipv4",
            "capture": "wlr",
            "encoder": "nvenc",
            "upnp": "disabled",
            "origin_web_ui_allowed": "lan",
            "port": 47989,
        }.items():
            self.assertEqual(settings[key], expected)
        self.assertFalse(self.config["capSysAdmin"])
        self.assertEqual(self.config["applications"]["apps"], [{"name": "Desktop"}])

    def test_authenticated_graphical_session_and_client(self):
        self.assertIn("graphical-session.target", self.config["wantedBy"])
        self.assertIn("uwsm", self.config["sessionCommand"])
        self.assertIn("start -F -- /run/current-system/sw/bin/start-hyprland", self.config["sessionCommand"])
        self.assertIn("moonlight-adam", self.config["clientPackages"])
        self.assertTrue(any(name.startswith("moonlight-qt-") for name in self.config["clientPackages"]))

    def test_port_restrictions_precede_existing_broad_accepts(self):
        firewall = self.config["firewall"]
        self.assertTrue(firewall["enable"])
        self.assertEqual(firewall["backend"], "iptables")
        rules = []
        apply_rules(rules, firewall["extraCommands"])
        self.assertEqual(len(rules), 4)
        for protocol, ports in PORTS.items():
            for port in ports:
                for interface, source, expected in (
                    ("wg0", "10.255.255.2", "ACCEPT"),
                    ("wg0", "10.255.255.3", "DROP"),
                    ("ens18", "10.255.255.2", "DROP"),
                    ("ens18", "10.12.0.2", "DROP"),
                    ("lo", "10.255.255.61", "DROP"),
                    ("lo", "127.0.0.1", "DROP"),
                ):
                    with self.subTest(protocol=protocol, port=port, interface=interface, source=source):
                        self.assertEqual(verdict(rules, interface, source, protocol, port), expected)
            self.assertEqual(verdict(rules, "ens18", "10.12.0.2", protocol, 3000), "ACCEPT")
        original = [rule[:] for rule in rules]
        apply_rules(rules, firewall["extraStopCommands"])
        self.assertEqual(rules, [])
        apply_rules(rules, firewall["extraCommands"])
        self.assertEqual(rules, original)


if __name__ == "__main__":
    unittest.main()
