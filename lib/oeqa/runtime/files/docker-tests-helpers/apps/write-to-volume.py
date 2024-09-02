import os
from pathlib import Path
volume_path = os.environ["MY_VOLUME_PATH"]
(Path(volume_path) / "written_by_container.txt").write_text("I'm here.\n")
