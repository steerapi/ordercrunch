compile:
	-cd web; make;
	-cd web-customer; make;
	-cd web-business; make;
	-cd web-employee; make;

run:
	-cd web; http-server compiled -p 8001 &
	-cd web-customer; http-server compiled -p 8002 &
	-cd web-business; http-server compiled -p 8003 &
	-cd web-employee; http-server compiled -p 8004 &

kill:
	killall http-server

watch:
	watch -n 1 make

deploy:
	cd web-business; make; af update
	cd web-customer; make; af update
	cd web-employee; make; af update
	cd web; make; af update
	cd backend; af update