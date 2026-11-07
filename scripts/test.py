from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
build=root/".build";build.mkdir(exist_ok=True)
source=(root/"Sources/main.swift").read_text().split('if CommandLine.arguments.contains("--validate-assets")')[0]
checks=(root/"Tests/checks.swift").read_text()
combined=build/"Tests.swift"; combined.write_text(source+checks)
subprocess.run(["swiftc",str(combined),"-o",str(build/"tests"),"-framework","Cocoa","-framework","CoreAudio"],check=True,cwd=root)
(root/"work/qa").mkdir(parents=True,exist_ok=True)
subprocess.run([str(build/"tests")],check=True,cwd=root)
