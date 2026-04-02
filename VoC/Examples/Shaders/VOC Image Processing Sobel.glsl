// https://www.shadertoy.com/view/XdG3Rw

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// Max Sills 2016
// Licensed under the MIT license.
//
// http://homepages.inf.ed.ac.uk/rbf/HIPR2/sobel.htm
// http://homepages.inf.ed.ac.uk/rbf/HIPR2/convolve.htm
//
// Using matrixCompMult, component-wise multiplication for convolution.
// OpenGL is mat[col][row].
/*
 0   1    2
 3   4(C) 5
 6   7    8
 Pixel 4 is the center
*/
// Given an array of pixels, return 3*3 matrix of pixel intensities.
mat3 intensityMatrix(vec4 n[9]){
    mat3 o;
    o[0] = vec3(sqrt(dot(n[0].xyz, n[0].xyz)), sqrt(dot(n[3].xyz, n[3].xyz)), sqrt(dot(n[6].xyz, n[6].xyz)));
    o[1] = vec3(sqrt(dot(n[1].xyz, n[1].xyz)), sqrt(dot(n[4].xyz, n[4].xyz)), sqrt(dot(n[7].xyz, n[7].xyz)));
    o[2] = vec3(sqrt(dot(n[2].xyz, n[2].xyz)), sqrt(dot(n[5].xyz, n[5].xyz)), sqrt(dot(n[8].xyz, n[8].xyz)));
	return o;
}

float convolution(mat3 x, mat3 y) {
 return dot(x[0],y[0]) + dot(x[1],y[1]) + dot(x[2],y[2]);
}

// Given a texture and  a center coordinate
// neighbors returns an array of the neighbor coordinates.
void neighbors(lowp sampler2D s, vec2 res, vec2 center, out vec4 n[9]) {
    n[0] = texture( s, (center + vec2(-1.0, 1.0)) / res);
    n[1] = texture( s, (center + vec2(0, 1.0)) / res);
    n[2] = texture( s, (center + vec2(1.0, 1.0)) / res);
    
    n[3] = texture( s, (center + vec2(-1.0, 0)) / res);
    n[4] = texture( s, (center) / res);
    n[5] = texture( s, (center + vec2(1.0, 0)) / res);
    
    n[6] = texture( s, (center + vec2(-1.0, -1.0)) / res);
    n[7] = texture( s, (center + vec2(0, -1.0)) / res);
    n[8] = texture( s, (center + vec2(1, -1.0)) / res);
}

float convolve(mat3 m1, mat3 m2){
    return 0.0;
}

void main()
{
    vec4 samples[9];
    neighbors(image, resolution.xy, gl_FragCoord.xy, samples);
    mat3 intensity = intensityMatrix(samples);

    mat3 Gx = mat3(1.0, 2.0,  1.0, // 1. column
                   0.0, 0.0,  0.0,  // 2. column
                   -1.0, -2.0,  -1.0); // 3. column
    
    mat3 Gy = mat3(-1.0, 0,   1.0,  // 1. column
                   -2.0, 0.0, 2.0,  // 2. column
                   -1.0, 0.0, 1.0); // 3. column
        
    float gx = convolution(intensity,Gx);
    float gy = convolution(intensity,Gy);
	float color = sqrt((gx*gx) + (gy*gy));
    
    glFragColor = vec4(color, color, color, 0.0);
    
}