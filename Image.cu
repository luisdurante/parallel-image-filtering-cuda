#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "Image.h"
#include "stb_image.h"
#include "stb_image_write.h"
#include <stdio.h>
#include <cstdio>
#include <stdint.h>
#include <stddef.h>
#include <cmath>
#include <string>

cudaError_t addWithCuda(uint8_t *originalData, unsigned int size, char filter);

__global__ void addKernelGray(uint8_t* originalData, unsigned int size, int totalThreads)
{
    int threadNum = threadIdx.x;
    int finished = 0;
    int pixelIndex = threadNum;

    while (finished == 0)
    {
        if (pixelIndex > size - 3) {
            break;
        }

        int gray = (originalData[pixelIndex] + originalData[pixelIndex+1] + originalData[pixelIndex+2]) / 3; 
        originalData[pixelIndex] = gray;
        pixelIndex += totalThreads;
    }
    


    //for (size_t i = 0; i < size; i++)
    //{
        
    //}
    
    /*else if (threadNum == 1) {
        for (size_t i = 0; i < size; i+= 3)
        {
            // https://www.techrepublic.com/blog/how-do-i/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/
            uint8_t inputRed = originalData[i]; 
            uint8_t inputGreen = originalData[i+1];
            uint8_t inputBlue = originalData[i+2];

            int red = (inputRed * 0.393) + (inputGreen * 0.769) + (inputBlue * 0.189); 
            int green = (inputRed * 0.349) + (inputGreen * 0.686) + (inputBlue * 0.168);
            int blue = (inputRed * 0.272) + (inputGreen * 0.534) + (inputBlue * 0.131);

            if(red > 255) red = 255;
            if(red < 0 ) red = 0;
            if(green > 255) green = 255;
            if(green < 0 ) green = 0;
            if(blue > 255) blue = 255;
            if(blue < 0 ) blue = 0;

            result_sepia[i] = red;
            result_sepia[i+1] = green;
            result_sepia[i+2] = blue;
        }
    } else if (threadNum == 2) {
        for (size_t i = 0; i < size; i+= 3)
        {
            originalData[i] = 255 - originalData[i];
            originalData[i+1] = 255 - originalData[i+1];
            originalData[i+2] = 255 - originalData[i+2];
        }
    }*/

}

__global__ void addKernelSepia(uint8_t* originalData, unsigned int size, int totalThreads)
{
    int threadNum = threadIdx.x;
    int finished = 0;
    int pixelIndex = threadNum;
    
    while (finished == 0)
    {
        if (pixelIndex > 0 && pixelIndex % 3 != 0) {
            pixelIndex += totalThreads;
            continue;
        }

        if (pixelIndex > size - 3) {
            break;
        }

        // https://www.techrepublic.com/blog/how-do-i/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c/
        uint8_t inputRed = originalData[pixelIndex]; 
        uint8_t inputGreen = originalData[pixelIndex+1];
        uint8_t inputBlue = originalData[pixelIndex+2];

        int red = (inputRed * 0.393) + (inputGreen * 0.769) + (inputBlue * 0.189); 
        int green = (inputRed * 0.349) + (inputGreen * 0.686) + (inputBlue * 0.168);
        int blue = (inputRed * 0.272) + (inputGreen * 0.534) + (inputBlue * 0.131);

        if(red > 255) red = 255;
        if(red < 0 ) red = 0;
        if(green > 255) green = 255;
        if(green < 0 ) green = 0;
        if(blue > 255) blue = 255;
        if(blue < 0 ) blue = 0;

        originalData[pixelIndex] = red;
        originalData[pixelIndex+1] = green;
        originalData[pixelIndex+2] = blue;
        
        pixelIndex += totalThreads;
    }
}

__global__ void addKernelInverted(uint8_t* originalData, unsigned int size, int totalThreads)
{
    int threadNum = threadIdx.x;
    int finished = 0;
    int pixelIndex = threadNum;

    while (finished == 0)
    {
        if (pixelIndex > 0 && pixelIndex % 3 != 0) {
            pixelIndex += totalThreads;
            continue;
        }

        if (pixelIndex > size - 3) {
            break;
        }

        originalData[pixelIndex] = 255 - originalData[pixelIndex];
        originalData[pixelIndex+1] = 255 - originalData[pixelIndex+1];
        originalData[pixelIndex+2] = 255 - originalData[pixelIndex+2];
        
        pixelIndex += totalThreads;
    }
}


class MyException : public std::exception
{
    private:
       std::string ex;
    public:
        MyException(const char* err) : ex(err) {}       
};

Image::Image(const char* fileName) {
    if(read(fileName)) {
        printf("Lendo %s\n", fileName);
        size = w * h * channels;
    } else {
        printf("Falha na leitura %s\n", fileName);
        throw MyException("Exception");
    }
}

Image::Image(int w, int h, int channels) : w(w), h(h), channels(channels){
    size = w * h * channels;
    data = new uint8_t[size];
}

Image::Image(const Image& img) : Image(img.w,img.h,img.channels) {
    memcpy(data, img.data, img.size);
}

Image::~Image() {
    stbi_image_free(data);
}

bool Image::read(const char* fileName) {
    data = stbi_load(fileName, &w, &h, &channels, 0);
    return data != NULL;
}

bool Image::write(const char* fileName) {
    ImageType type = getFileType(fileName);
	int success;
    switch (type) {
        case PNG:
            success = stbi_write_png(fileName, w, h, channels, data, w * channels);
        break;
        case BMP:
            success = stbi_write_bmp(fileName, w, h, channels, data);
        break;
        case JPG:
            success = stbi_write_jpg(fileName, w, h, channels, data, 100);
        break;
        case TGA:
            success = stbi_write_tga(fileName, w, h, channels, data);
        break;
    }
    return success != 0;
}

ImageType Image::getFileType(const char* fileName) {
    const char* ext = strrchr(fileName, '.');
	if(ext != nullptr) {
		if(strcmp(ext, ".png") == 0) {
			return PNG;
		}
		else if(strcmp(ext, ".jpg") == 0) {
			return JPG;
		}
		else if(strcmp(ext, ".bmp") == 0) {
			return BMP;
		}
		else if(strcmp(ext, ".tga") == 0) {
			return TGA;
		}
	}
	return PNG;
}

Image& Image::grayscale_lum() {
    // preserva a luminosidade
    if (channels < 3) {
        throw MyException("Exception");
    } else {
        addWithCuda(data, size, 'g');
    }
    return *this;
}

Image& Image::sepia() {
    if (channels < 3) {
        throw MyException("Exception");
    } else {
        addWithCuda(data, size, 's');
    }

    return *this;
}

Image& Image::invertColors() {
    if (channels < 3) {
        throw MyException("Exception");
    } else {
        addWithCuda(data, size, 'i');
    }
    return *this;
}

cudaError_t addWithCuda(uint8_t *originalData, unsigned int size, char filter)
{
    uint8_t *dev_originalData = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }
    
    cudaStatus = cudaMalloc((void**)&dev_originalData, size * sizeof(uint8_t));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_originalData, originalData, size * sizeof(uint8_t), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }
  
    // Launch a kernel on the GPU with one thread for each element.
    if (filter == 'g')
        addKernelGray<<<1, 1024>>>(dev_originalData,  size, 1024);
    else if (filter == 's')
        addKernelSepia<<<1, 1024>>>(dev_originalData, size, 1024);
    else
        addKernelInverted<<<1, 1024>>>(dev_originalData, size, 1024);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(originalData, dev_originalData, size * sizeof(uint8_t), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed! passo 9");
        goto Error;
    }

Error:
    cudaFree(dev_originalData);
    
    return cudaStatus;
}