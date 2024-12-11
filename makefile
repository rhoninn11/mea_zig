


build:
	zig build -Dalt --prefix web_demo/prebuilt

host:
	cd web_demo && python3 -m http.server
	