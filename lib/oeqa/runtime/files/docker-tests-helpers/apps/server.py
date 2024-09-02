import os
import socket
import logging

logging.basicConfig()
logger = logging.getLogger("server")
logger.setLevel(logging.INFO)

own_host = os.environ["PING_SERVER_HOST"]
own_port = int(os.environ["PING_SERVER_PORT"])
own_address = (own_host, own_port)

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(own_address)
logger.info("Created socket")
s.settimeout(30)
logger.info(f"Listening for 'ping' on {own_address}")
ping, pinger = s.recvfrom(4)

if ping == b"ping":
    try:
        logger.info(f"Received 'ping'")
        s.sendto(b"pong", pinger)
        logger.info(f"Sended 'pong'")
    except socket.timeout as e:
        raise RuntimeError("No ping request received.") from e

