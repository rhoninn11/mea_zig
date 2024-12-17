

dev: zigBuildWeb jsWebLocal
devDkr: zigBuildWeb jsWebHost

	

run-app:
	zig build run --prefix fs

build-app:
	zig build --prefix fs

zigBuildWeb:
	zig build -Dalt --prefix web_demo/public

jsWebLocal:
	cd web_demo && npx vite

jsWebHost:
	cd web_demo && npx vite --host

npm-install:
	cd web_demo && npm install

