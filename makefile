
run-app:
	zig build run --prefix fs

build-app:
	zig build --prefix fs

build-web:
	zig build -Dalt --prefix web_demo/public

web-dev:
	cd web_demo && npx vite

web-dev-host:
	cd web_demo && npx vite --host

npm-install:
	cd web_demo && npm install
	