import os
import socket
import logging

logging.basicConfig()
logger = logging.getLogger("client")
logger.setLevel(logging.INFO)

ping_server_host = os.environ["PING_SERVER_HOST"]
ping_server_port = int(os.environ["PING_SERVER_PORT"])
ping_server_address = (ping_server_host, ping_server_port)


s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
logger.info("Created socket")
s.settimeout(5)

for i in range(10):
    try:
        logger.info(f"Send 'ping' to {ping_server_address}")
        s.sendto(b"ping", ping_server_address)
        logger.info(f"Wait 'pong' on {s.getsockname()}")
        pong, addr = s.recvfrom(4)
        break
    except socket.timeout:
        logger.info(f"Timeout {i}/10. Retrying...")
        continue
else:
    raise RuntimeError("Couldn't reach the pint server")

assert pong != b"ping", "Response doesn't match to 'ping'"
logger.info(f"Received 'pong'")
