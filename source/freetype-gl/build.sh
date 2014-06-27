gcc -m64 -std=gnu99 -c -o render.o render.c -static -lGLEW -lGL -lglfw -lm
gcc -m64 -std=gnu99 -c -o spline.o spline.c -static -llapack -lm
ar rcs libspline.a *.o
rm *.o
