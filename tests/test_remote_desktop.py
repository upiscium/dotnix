"""Locked Nix configuration and non-privileged Sunshine firewall policy checks."""

import ipaddress
import json
import os
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
            serverHome = (load "adam").homeConfigurations.home.config;
            uinputRule = builtins.head (builtins.filter
              (package: package.name == "adam-sunshine-uinput-access") server.services.udev.packages);
          in {{
            inherit (server.services.sunshine) settings capSysAdmin applications;
            firewall = {{
              inherit (server.networking.firewall) enable backend extraCommands extraStopCommands;
            }};
            sessionCommand = server.services.greetd.settings.default_session.command;
            wantedBy = server.systemd.user.services.sunshine.wantedBy;
            clientPackages = map (package: package.name) client.home.packages;
            gpuEnvironment = serverHome.home.file.".config/uwsm/env".text;
            udevRules = server.services.udev.extraRules;
            startupChecks = server.systemd.user.services.sunshine.serviceConfig.ExecStartPre;
            startupCheckContext = builtins.getContext (builtins.head server.systemd.user.services.sunshine.serviceConfig.ExecStartPre);
            startupTimeout = server.systemd.user.services.sunshine.serviceConfig.TimeoutStartSec;
            uinputRuleContext = builtins.getContext (toString uinputRule);
            userGroups = server.users.users.upiscium.extraGroups;
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
            "output_name": "SUNSHINE",
            "upnp": "disabled",
            "origin_web_ui_allowed": "lan",
            "port": 47989,
        }.items():
            self.assertEqual(settings[key], expected)
        self.assertFalse(self.config["capSysAdmin"])
        self.assertEqual(self.config["applications"]["apps"], [{"name": "Desktop"}])

    def test_csrf_trusts_only_the_direct_vpn_web_ui(self):
        settings = self.config["settings"]
        expected = f"https://{settings['bind_address']}:{settings['port'] + 1}"
        self.assertEqual(expected, "https://10.255.255.61:47990")
        self.assertEqual(settings["csrf_allowed_origins"].split(","), [expected])
        self.assertEqual(settings["origin_web_ui_allowed"], "lan")

    def test_adam_uses_a_stable_nvidia_card_and_a_guarded_output(self):
        environment = self.config["gpuEnvironment"]
        self.assertIn("export GBM_BACKEND=nvidia-drm", environment)
        self.assertIn("export AQ_DRM_DEVICES=/dev/dri/adam-nvidia", environment)
        self.assertNotIn("/dev/dri/card1", environment)
        self.assertNotIn("/dev/dri/renderD128", environment)
        rules = self.config["udevRules"]
        self.assertIn('KERNELS=="0000:01:00.0"', rules)
        self.assertIn('ENV{DEVTYPE}=="drm_minor"', rules)
        self.assertIn('ATTRS{vendor}=="0x10de"', rules)
        self.assertIn('SYMLINK+="dri/adam-nvidia"', rules)
        self.assertEqual(self.config["startupTimeout"], "30s")
        self.assertEqual(len(self.config["startupChecks"]), 1)
        self.assertTrue(self.config["startupChecks"][0].endswith("/bin/adam-sunshine-display-ready"))

    def test_virtual_input_access_is_seat_scoped_not_a_broad_group(self):
        context = self.config["uinputRuleContext"]
        paths = [path for path in context if path.endswith("-adam-sunshine-uinput-access.drv")]
        self.assertEqual(len(paths), 1)
        result = subprocess.run(
            ["nix", "derivation", "show", paths[0]],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
        payload = json.loads(result.stdout)
        records = payload.get("derivations", payload)
        record = records.get(paths[0], records.get(Path(paths[0]).name))
        attributes = record.get("structuredAttrs", record["env"])
        self.assertEqual(attributes["destination"], "/lib/udev/rules.d/70-adam-sunshine-uinput.rules")
        self.assertEqual(attributes["text"].strip(),
                         'SUBSYSTEM=="misc", KERNEL=="uinput", TAG+="uaccess", OPTIONS+="static_node=uinput"')
        self.assertNotIn("input", self.config["userGroups"])
        self.assertNotIn("uinput", self.config["userGroups"])

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


@unittest.skipUnless(shutil.which("nix"), "Nix is required to evaluate the configuration")
class SunshineReadinessTests(unittest.TestCase):
    """Run the actual generated gate with fake IPC/capture, never a live desktop."""

    @classmethod
    def setUpClass(cls):
        # Reuse the locked configuration snapshot when running the full suite.
        if not hasattr(RemoteDesktopTests, "config"):
            RemoteDesktopTests.setUpClass()
        context = RemoteDesktopTests.config["startupCheckContext"]
        derivations = [path for path in context if path.endswith("-adam-sunshine-display-ready.drv")]
        if len(derivations) != 1:
            raise AssertionError(f"Unexpected readiness derivation context: {context}")
        derivation = derivations[0]
        result = subprocess.run(
            ["nix", "derivation", "show", derivation],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
        payload = json.loads(result.stdout)
        records = payload.get("derivations", payload)
        record = records.get(derivation, records.get(Path(derivation).name))
        if record is None:
            raise AssertionError(f"Readiness derivation missing from metadata: {derivation}")
        cls.script = record.get("structuredAttrs", {}).get("text", record["env"].get("text"))
        if not isinstance(cls.script, str):
            raise AssertionError("Readiness derivation metadata has no shell text")
        # Realize the small shell application and its pinned runtime dependencies
        # so its PATH includes jq. This also runs its Bash/ShellCheck build checks.
        # The readiness application itself is NOT executed against the desktop.
        subprocess.run(
            ["nix", "build", "--no-link", f"{derivation}^out"],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )

    def run_gate(self, monitors, frame_ok=True, ipc_ok=True, frame_stalls=False, input_writable=True):
        mocks = r'''
          test() {
            if [ "$#" = 2 ] && [ "$1" = -w ] && [ "$2" = /dev/uinput ]; then
              [ "$TEST_UINPUT_OK" = 1 ]
            else
              builtin test "$@"
            fi
          }
          hyprctl() {
            if [ "$TEST_IPC_OK" != 1 ]; then return 1; fi
            printf '%s\n' "$TEST_MONITORS"
          }
          grim() {
            printf 'MOCK_FRAME_REQUESTED\n' >&2
            if [ "$TEST_FRAME_OK" != 1 ]; then return 1; fi
            printf 'mock frame bytes'
          }
          timeout() {
            if [ "$1" != '--kill-after=2s' ] || [ "$2" != '10s' ]; then
              printf 'INVALID_CAPTURE_TIMEOUT\n' >&2
              return 125
            fi
            printf 'MOCK_CAPTURE_TIMEOUT_BOUND_VERIFIED\n' >&2
            shift 2
            if [ "$TEST_FRAME_STALLS" = 1 ]; then
              # Exercise the real timeout return path on an inert subprocess,
              # with a scaled-down deadline; never invoke a real capture client.
              command timeout --kill-after=0.1s 0.05s "$BASH" -c 'sleep 30'
              return "$?"
            fi
            "$@"
          }
          sleep() { :; }
        '''
        environment = dict(os.environ)
        environment.update(
            TEST_MONITORS=json.dumps(monitors),
            TEST_FRAME_OK="1" if frame_ok else "0",
            TEST_IPC_OK="1" if ipc_ok else "0",
            TEST_FRAME_STALLS="1" if frame_stalls else "0",
            TEST_UINPUT_OK="1" if input_writable else "0",
        )
        return subprocess.run(
            ["bash", "-c", mocks + "\n" + self.script],
            cwd=ROOT, env=environment, capture_output=True, text=True, timeout=10,
        )

    @staticmethod
    def ready_monitor():
        return {
            "name": "SUNSHINE", "disabled": False, "dpmsStatus": True,
            "width": 1920, "height": 1080, "refreshRate": 60.0,
        }

    def test_ready_output_and_frame_pass_without_storing_image(self):
        result = self.run_gate([self.ready_monitor()])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("MOCK_FRAME_REQUESTED", result.stderr)
        self.assertIn("MOCK_CAPTURE_TIMEOUT_BOUND_VERIFIED", result.stderr)
        self.assertEqual(result.stdout, "")

    def test_absent_or_incorrect_output_rejects_without_capture(self):
        good = self.ready_monitor()
        cases = [[], [dict(good, name="Virtual-1")], [dict(good, disabled=True)],
                 [dict(good, dpmsStatus=False)], [dict(good, width=1280)],
                 [dict(good, height=800)], [dict(good, refreshRate=30.0)]]
        for monitors in cases:
            with self.subTest(monitors=monitors):
                result = self.run_gate(monitors)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("MOCK_FRAME_REQUESTED", result.stderr)

    def test_failed_frame_rejects(self):
        result = self.run_gate([self.ready_monitor()], frame_ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no first screencopy frame", result.stderr)

    def test_stalled_frame_rejects_after_bounded_timeout(self):
        result = self.run_gate([self.ready_monitor()], frame_stalls=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("MOCK_CAPTURE_TIMEOUT_BOUND_VERIFIED", result.stderr)
        self.assertIn("no first screencopy frame", result.stderr)
        self.assertNotIn("MOCK_FRAME_REQUESTED", result.stderr)

    def test_failed_ipc_rejects_without_capture(self):
        result = self.run_gate([self.ready_monitor()], ipc_ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("MOCK_FRAME_REQUESTED", result.stderr)

    def test_missing_virtual_input_access_rejects_without_capture(self):
        result = self.run_gate([self.ready_monitor()], input_writable=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no write access to /dev/uinput", result.stderr)
        self.assertNotIn("MOCK_FRAME_REQUESTED", result.stderr)


if __name__ == "__main__":
    unittest.main()
