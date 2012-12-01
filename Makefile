all:
	cd web-business; make; af update
	cd web-customer; make; af update
	cd web-employee; make; af update
	cd web; make; af update
	cd backend; af update