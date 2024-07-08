from typing import Set
import unittest
import logging
import subprocess
import json


def dprint(x):
    print(x)
    return x


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

    result = subprocess.run(
        "docker container list --all --format '{{json . }}'",
        shell=True,
        capture_output=True,
    )
    output = result.stdout.decode(errors="ignore")
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

    result = subprocess.run(
        "docker image list --all --format '{{json . }}'",
        shell=True,
        capture_output=True,
    )
    output = result.stdout.decode(errors="ignore")
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
    result = subprocess.run(
        "docker volume list --format '{{json . }}'",
        shell=True,
        capture_output=True,
    )
    output = result.stdout.decode(errors="ignore")
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
    result = subprocess.run(
        "docker network list --format '{{json . }}'",
        shell=True,
        capture_output=True,
    )
    output = result.stdout.decode(errors="ignore")
    volumes = [json.loads(line) for line in output.splitlines()]
    return volumes


def rm_containers():
    containers = get_all_containers()
    if containers:
        containers_list = " ".join(c["ID"] for c in containers)
        rm_command = f"docker container rm -f {containers_list}"
        subprocess.run(rm_command, shell=True, capture_output=True, check=True)


class TestDockerCreate(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        logging.basicConfig()
        logging.root.setLevel(logging.WARNING)

    def setUp(self) -> None:
        rm_containers()
        logging.debug("Setup: Removing exited containers.")
        subprocess.run(
            "docker volume create --name=my-vol",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

    def test_pull_and_run(self):
        images = get_images()
        hello_world_image = [
            i for i in images if "hello-world:linux" == f"{i['Repository']}:{i['Tag']}"
        ]
        if hello_world_image:
            logging.debug("Removing hello-world:linux")
            subprocess.run(
                "docker image rm -f hello-world:linux",
                shell=True,
                check=True,
                capture_output=True,
            )

        logging.debug("Pulling and running hello-world:linux")
        result = subprocess.run(
            "docker run --rm hello-world:linux",
            shell=True,
            capture_output=True,
        )
        # output = result.stdout.decode(errors="ignore")
        error = result.stderr.decode(errors="ignore")
        self.assertEqual(result.returncode, 0, error)

    def test_create(self):
        running_containers = get_all_containers()
        created_hello_world_containers = [
            c
            for c in running_containers
            if c["State"] == "created" and c["Image"] == "hello-world:linux"
        ]
        if created_hello_world_containers:
            containers_list = " ".join(c["ID"] for c in created_hello_world_containers)
            rm_command = f"docker container rm {containers_list}"
            subprocess.run(rm_command, shell=True, check=True, capture_output=True)

        subprocess.run(
            "docker container create hello-world:linux",
            shell=True,
            check=True,
            capture_output=True,
        )

        running_containers = get_all_containers()
        created_hello_world_containers = [
            c
            for c in running_containers
            if c["State"] == "created" and c["Image"] == "hello-world:linux"
        ]
        self.assertEqual(1, len(created_hello_world_containers))
        containers_list = " ".join(c["ID"] for c in created_hello_world_containers)
        rm_command = f"docker container rm {containers_list}"
        subprocess.run(rm_command, shell=True, check=True, capture_output=True)

    def test_compose(self):
        up = subprocess.run(
            "docker-compose up --build ping-client ping-server",
            shell=True,
            capture_output=True,
            cwd="./apps",
        )
        down = subprocess.run(
            "docker-compose down", shell=True, capture_output=True, cwd="./apps"
        )
        self.assertEqual(up.returncode, 0)
        self.assertEqual(down.returncode, 0)

    def test_compose_port_forward(self):
        subprocess.run(
            "docker-compose build ping-server",
            shell=True,
            capture_output=True,
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
        subprocess.run(
            "docker-compose build",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )
        subprocess.run(
            "docker volume rm my-vol",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

        subprocess.run(
            "docker volume create --name=my-vol",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

        subprocess.run(
            "docker-compose run volume-writer",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

        result = subprocess.run(
            "docker-compose run cat",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )
        self.assertIn("I'm here.", result.stdout.decode(errors="ignore"))

        subprocess.run(
            "docker-compose down",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

    def test_inspect(self):
        subprocess.run(
            "docker-compose up",
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            cwd="./apps",
            check=True,
        )

        containers = get_all_containers()
        result = subprocess.run(
            f"docker container inspect {containers[0]['ID']}",
            shell=True,
            capture_output=True,
        )
        self.assertEqual(0, result.returncode)
        json.loads(result.stdout.decode(errors="ignore"))

        images = get_images()
        result = subprocess.run(
            f"docker image inspect {images[0]['ID']}",
            shell=True,
            capture_output=True,
        )
        self.assertEqual(0, result.returncode)
        json.loads(result.stdout.decode(errors="ignore"))

        volumes = get_volumes()
        result = subprocess.run(
            f"docker volume inspect {volumes[0]['Name']}",
            shell=True,
            capture_output=True,
        )
        self.assertEqual(0, result.returncode)
        json.loads(result.stdout.decode(errors="ignore"))

        networks = get_networks()
        result = subprocess.run(
            f"docker network inspect {networks[0]['Name']}",
            shell=True,
            capture_output=True,
        )
        self.assertEqual(0, result.returncode)
        json.loads(result.stdout.decode(errors="ignore"))

        subprocess.run(
            "docker-compose down",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

    def test_logs(self):
        up = subprocess.run(
            "docker-compose up --build ping-client ping-server",
            shell=True,
            capture_output=True,
            cwd="./apps",
        )
        self.assertEqual(up.returncode, 0)

        exited_containers = [
            c
            for c in get_all_containers()
            if (c["State"]) == "exited" and ("ping-client" in c["Names"])
        ]

        self.assertTrue(len(exited_containers) > 0)

        result = subprocess.run(
            f"docker logs {exited_containers[0]['Names']}",
            shell=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn(
            "INFO:client:Received 'pong'", result.stderr.decode(errors="ignore")
        )

        down = subprocess.run(
            "docker-compose down", shell=True, capture_output=True, cwd="./apps"
        )
        self.assertEqual(down.returncode, 0)

    def test_privileged(self):
        no_privileged = subprocess.run(
            "docker run -t --rm ubuntu mount -t tmpfs none /mnt",
            shell=True,
            capture_output=True,
        )
        self.assertNotEqual(no_privileged.returncode, 0)
        privileged = subprocess.run(
            "docker run --privileged -t --rm ubuntu mount -t tmpfs none /mnt",
            shell=True,
            capture_output=True,
            cwd="./apps",
        )
        self.assertEqual(privileged.returncode, 0)

    def tearDown(self):
        rm_containers()
        logging.debug("Tear Down: Removing exited containers.")
        subprocess.run(
            "docker volume rm my-vol",
            shell=True,
            capture_output=True,
            cwd="./apps",
            check=True,
        )

    @classmethod
    def tearDownClass(cls):
        subprocess.run(
            "docker container prune -f",
            shell=True,
            capture_output=True,
            check=True,
        )
        subprocess.run(
            "docker image rm ping-image ubuntu hello-world:linux",
            shell=True,
            capture_output=True,
            check=True,
        )
        subprocess.run(
            "docker image prune -a -f",
            shell=True,
            capture_output=True,
            check=True,
        )
        subprocess.run(
            "docker system prune -f",
            shell=True,
            capture_output=True,
            check=True,
        )
