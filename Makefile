OBJS	= main.o Image.o
SOURCE	= main.cpp Image.cpp
HEADER	= Image.h stb_image.h stb_image_write.h
OUT	= output
CC = g++
NVCC=nvcc
FLAGS	 = -g -c -Wall
CUDA_FLAGS=-c
LFLAGS	 = 

all: $(OBJS)
	$(CC) $(OBJS) -L/usr/local/cuda/lib64 -lcuda -lcudart -o $(OUT) $(LFLAGS)

main.o: main.cpp
	$(CC) $(FLAGS) main.cpp 

Image.o: Image.cu
	$(NVCC) $(CUDA_FLAGS) Image.cu 


clean:
	rm -f $(OBJS) $(OUT)