

dev: zigBuildWeb jsWebLocal
devDkr: zigBuildWeb jsWebHost

	

run_app:
	zig build run --prefix fs

app_build:
	zig build --prefix fs

app_test:
	zig build --prefix fs test

zigBuildWeb:
	zig build -Dalt --prefix web_demo/public

jsWebLocal:
	cd web_demo && npx vite

jsWebHost:
	cd web_demo && npx vite --host

npm-install:
	cd web_demo && npm install

