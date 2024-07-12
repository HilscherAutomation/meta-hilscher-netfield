import unittest
import logging
import subprocess
import json
from pathlib import Path
from typing import Tuple
import sys

a = Path("/etc/os-release")
kv = dict([i.split("=") for i in a.read_text().splitlines()])
operating_system_name = kv["NAME"]  # "netFIELD OS"
is_on_netfield_os = operating_system_name == '"netFIELD OS"'

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(message)s")
handler.setFormatter(formatter)
logger = logging.getLogger("test_docker_on_device")
logger.setLevel(logging.DEBUG)
logger.addHandler(handler)

logger.info(f"is_on_netfield_os={is_on_netfield_os}")


def run_cmd(cmd: str, *, throw: bool = False, **kwargs) -> Tuple[bool, str, str]:
    logger.debug(f"\n=============CMD=================")
    logger.debug(f"{cmd}")
    ret = subprocess.run(cmd, shell=True, capture_output=True, check=False, **kwargs)
    std_output: str = ret.stdout.decode(errors="ignore")
    err_output: str = ret.stderr.decode(errors="ignore")
    logger.debug(f"------------STDOUT---------------")
    logger.debug(f"{std_output.strip()}")
    logger.debug(f"------------STDERR---------------")
    logger.debug(f"{err_output.strip()}")
    logger.debug(f"=================================")
    if throw and ret.returncode != 0:
        raise RuntimeError(f"'{cmd}' returned non-zero.")
    return ret.returncode == 0, std_output, err_output


def get_all_containers():
    # container info

    # {'Command': '"/usr/local/bin/pkcs…"',
    #  'CreatedAt': '2021-09-08 12:52:30 +0200 CEST',
    #  'ID': 'cc8f31a1438e',
    #  'Image': 'pkcs11-proxy:latest',
    #  'Labels': '',
    #  'LocalVolumes': '0',
    #  'Mounts': '/home/mtrensch…',
    #  'Names': 'pkcs11-softhsm',
    #  'Networks': 'bridge',
    #  'Ports': '0.0.0.0:5657->5657/tcp, :::5657->5657/tcp',
    #  'RunningFor': '2 years ago',
    #  'Size': '23.2MB (virtual 161MB)',
    #  'State': 'running',
    #  'Status': 'Up 4 months'}

    _, output, _ = run_cmd("docker container list --all --format '{{json . }}'")
    containers = [json.loads(line) for line in output.splitlines()]
    return containers


def get_images():
    # {'Containers': 'N/A',
    #  'CreatedAt': '2018-01-17 06:52:35 +0100 CET',
    #  'CreatedSince': '6 years ago',
    #  'Digest': '<none>',
    #  'ID': '40bd78fee54c',
    #  'Repository': 'subfuzion/netcat',
    #  'SharedSize': 'N/A',
    #  'Size': '4.27MB',
    #  'Tag': 'latest',
    #  'UniqueSize': 'N/A',
    #  'VirtualSize': '4.267MB'}
    _, output, _ = run_cmd("docker image list --all --format '{{json . }}'")
    images = [json.loads(line) for line in output.splitlines()]
    return images


def get_volumes():
    # volumes
    # {'Driver': 'local',
    #  'Labels': '',
    #  'Links': 'N/A',
    #  'Mountpoint': '/var/lib/docker/volumes/my-vol/_data',
    #  'Name': 'my-vol',
    #  'Scope': 'local',
    #  'Size': 'N/A'}
    _, output, _ = run_cmd("docker volume list --format '{{json . }}'")
    volumes = [json.loads(line) for line in output.splitlines()]
    return volumes


def get_networks():
    # networks
    # {'CreatedAt': '2024-06-26 09:54:08.696065827 +0200 CEST',
    #  'Driver': 'bridge',
    #  'ID': '72fcce94708d',
    #  'IPv6': 'false',
    #  'Internal': 'false',
    #  'Labels': 'com.docker.compose.network=default,com.docker.compose.project=apps,com.docker.compose.version=1.29.2',
    #  'Name': 'apps_default',
    #  'Scope': 'local'}
    _, output, _ = run_cmd("docker network list --format '{{json . }}'")
    volumes = [json.loads(line) for line in output.splitlines()]
    return volumes


def rm_containers():
    containers = get_all_containers()
    if containers and is_on_netfield_os:
        containers_list = " ".join(c["ID"] for c in containers)
        rm_command = f"docker container rm -f {containers_list}"
        run_cmd(rm_command, throw=True)


class TestDockerCreate(unittest.TestCase):

    def setUp(self) -> None:
        rm_containers()
        run_cmd("docker volume create --name=my-vol", cwd="./apps", throw=True)

    def test_pull_and_run(self):
        logger.info("Runnig: test_pull_and_run")
        images = get_images()
        hello_world_image = [
            i for i in images if "hello-world:linux" == f"{i['Repository']}:{i['Tag']}"
        ]
        if hello_world_image:
            run_cmd("docker image rm -f hello-world:linux", throw=True)

        rc, _, error = run_cmd("docker run --rm hello-world:linux")
        self.assertTrue(rc, error)

    def test_create(self):
        logger.info("Runnig: test_create")
        running_containers = get_all_containers()
        created_hello_world_containers = [
            c
            for c in running_containers
            if c["State"] == "created" and c["Image"] == "hello-world:linux"
        ]
        if created_hello_world_containers:
            containers_list = " ".join(c["ID"] for c in created_hello_world_containers)
            rm_command = f"docker container rm {containers_list}"
            run_cmd(rm_command, throw=True)

        run_cmd("docker container create hello-world:linux", throw=True)

        running_containers = get_all_containers()
        created_hello_world_containers = [
            c
            for c in running_containers
            if c["State"] == "created" and c["Image"] == "hello-world:linux"
        ]
        self.assertEqual(1, len(created_hello_world_containers))
        containers_list = " ".join(c["ID"] for c in created_hello_world_containers)
        rm_command = f"docker container rm {containers_list}"
        run_cmd(rm_command, throw=True)

    def test_compose(self):
        logger.info("Runnig: test_compose")
        up, _, _ = run_cmd(
            "docker-compose up --build ping-client ping-server",
            cwd="./apps",
        )
        down, _, _ = run_cmd(
            "docker-compose down -v --rmi all --remove-orphans",
            cwd="./apps",
        )
        self.assertTrue(up)
        self.assertTrue(down)

    def test_compose_port_forward(self):
        logger.info("Runnig: test_compose_port_forward")
        run_cmd(
            "docker-compose build ping-server",
            cwd="./apps",
        )
        images = get_images()
        image_ping_server = [i for i in images if "ping-image" in i["Repository"]][0]
        id = image_ping_server["ID"]
        server = subprocess.Popen(
            f"docker run --rm -p 8000:8000/udp --env PING_SERVER_HOST=0.0.0.0 --env PING_SERVER_PORT=8000 -t {id} python server.py",
            shell=True,
            cwd="./apps",
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        client = subprocess.Popen(
            f"PING_SERVER_HOST=localhost PING_SERVER_PORT=8000 python3 client.py",
            shell=True,
            cwd="./apps",
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        server.wait()
        client.wait()
        self.assertEqual(0, client.returncode)
        self.assertEqual(0, server.returncode)

    def test_compose_volume(self):
        logger.info("Runnig: test_compose_volume")
        run_cmd("docker-compose build", cwd="./apps", throw=True)
        run_cmd("docker volume rm my-vol", cwd="./apps", throw=True)
        run_cmd("docker volume create --name=my-vol", cwd="./apps", throw=True)
        run_cmd("docker-compose run volume-writer", cwd="./apps", throw=True)
        _, output, _ = run_cmd("docker-compose run cat", cwd="./apps", throw=True)

        self.assertIn("I'm here.", output)

        run_cmd(
            "docker-compose down -v --rmi all --remove-orphans",
            cwd="./apps",
            throw=True,
        )

    def test_inspect(self):
        logger.info("Runnig: test_inspect")
        run_cmd(
            "docker-compose up",
            cwd="./apps",
            throw=True,
        )

        containers = get_all_containers()
        rc, output, _ = run_cmd(f"docker container inspect {containers[0]['ID']}")
        self.assertTrue(rc)
        json.loads(output)

        images = get_images()
        rc, output, _ = run_cmd(f"docker image inspect {images[0]['ID']}")
        self.assertTrue(rc)
        json.loads(output)

        volumes = get_volumes()
        rc, output, _ = run_cmd(f"docker volume inspect {volumes[0]['Name']}")
        self.assertTrue(rc)
        json.loads(output)

        networks = get_networks()
        rc, output, _ = run_cmd(f"docker network inspect {networks[0]['Name']}")
        self.assertTrue(rc)
        json.loads(output)

        run_cmd(
            "docker-compose down -v --rmi all --remove-orphans",
            cwd="./apps",
            throw=True,
        )

    def test_logs(self):
        logger.info("Runnig: test_logs")
        run_cmd(
            "docker-compose up --build ping-client ping-server",
            cwd="./apps",
            throw=True,
        )

        exited_containers = [
            c
            for c in get_all_containers()
            if (c["State"]) == "exited" and ("ping-client" in c["Names"])
        ]

        self.assertTrue(len(exited_containers) > 0)

        rt, _, err_output = run_cmd(f"docker logs {exited_containers[0]['Names']}")
        self.assertTrue(rt)
        self.assertIn("INFO:client:Received 'pong'", err_output)

        run_cmd(
            "docker-compose down -v --rmi all --remove-orphans",
            cwd="./apps",
            throw=True,
        )

    def test_privileged(self):
        logger.info("Runnig: test_privileged")
        rt = run_cmd("docker run -t --rm ubuntu mount -t tmpfs none /mnt")
        self.assertFalse(rt[0])
        run_cmd(
            "docker run --privileged -t --rm ubuntu mount -t tmpfs none /mnt",
            throw=True,
        )

    def tearDown(self):
        rm_containers()
        run_cmd("docker volume rm my-vol", cwd="./apps", throw=True)

    @classmethod
    def tearDownClass(cls):

        if is_on_netfield_os:
            result = run_cmd("docker container prune -f")[0]
            result &= run_cmd("docker image rm ubuntu hello-world:linux")[0]
            result &= run_cmd("docker image prune -a -f")[0]
            result &= run_cmd("docker system prune -f")[0]
            if not result:
                raise RuntimeError("Error by cleanup")
