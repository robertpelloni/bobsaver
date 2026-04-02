#version 430

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;
uniform float random1;

//image2D layouts that act as 32 bit single precision arrays for passing data to/from Visions of Chaos
//image2D for random numbers - 20 images "tall" so it is like 10 stacked 2D arrays
layout (binding=0,r32f) uniform image2D randomlcg;
//can have up to 7 maximum layers here (this is due to an OpenGL limitation)
//each is 2x height so top and bottom half can be read/written to alternatively each frame
layout (binding=1,r32f) uniform image2D layer1;
layout (binding=2,r32f) uniform image2D layer2;
layout (binding=3,r32f) uniform image2D layer3;
layout (binding=4,r32f) uniform image2D layer4;
layout (binding=5,r32f) uniform image2D layer5;
layout (binding=6,r32f) uniform image2D layer6;
layout (binding=7,r32f) uniform image2D layer7;

int x_pixel,y_pixel,xp,yp,x_res,y_res,range,range_div;
float layer1_result,layer2_result,layer3_result;

///////////////////////////////////////////////////////////////////////////////
// Random function
///////////////////////////////////////////////////////////////////////////////

//random function - returns a float between 0 and 1
float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//random value from the passed random_lcg Image2D array
//co is the current pixel coordinates
//layer can be anything from 0 to 19 and will give a different random result
float random_lcg(vec2 co,int layer) {
	return imageLoad( randomlcg, ivec2(co.x,co.y+layer*y_res) ).r;
}

///////////////////////////////////////////////////////////////////////////////
// Color routines
///////////////////////////////////////////////////////////////////////////////

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 yuv2rgb(vec3 c) {
	vec4 yuva = vec4(c.x, (c.y - 0.5), (c.z - 0.5), 1.0);
	vec3 rgb = vec3(0.0);
	rgb.r = yuva.x * 1.0 + yuva.y * 0.0 + yuva.z * 1.4;
	rgb.g = yuva.x * 1.0 + yuva.y * -0.343 + yuva.z * -0.711;
	rgb.b = yuva.x * 1.0 + yuva.y * 1.765 + yuva.z * 0.0;
	return rgb;
}

void contrast( inout vec3 color, float adjust ) {
    color.rgb = ( color.rgb - vec3(0.5) ) * adjust+0.5;
}

///////////////////////////////////////////////////////////////////////////////
// Functions to read/write float values from/to the passed Image2D r32f arrays
// Because you cannot read and write to the same memory locations without data
// corruption the arrays are 2 stacked 2d arrays on top of each other.  This
// saves having to "ping pong" fbos outside the shader.
///////////////////////////////////////////////////////////////////////////////

//read float value from image2d
float read_array(int xp, int yp, int which_layer) {
	//The offset calculation determines if the top of bottom half of the texture
	//should be read from.  this alternates every frame.  The write_array
	//function uses the opposite half so the top half is read when the bottom
	//half is written to.  Then they swap for the next frame.
	int offset=0;
	if (mod(frames,2)>0) { offset=y_res; }
	float return_value=0;
	switch (which_layer) {
		case 1:return_value=imageLoad( layer1, ivec2(xp,yp+offset)).r; break;
		case 2:return_value=imageLoad( layer2, ivec2(xp,yp+offset)).r; break;
		case 3:return_value=imageLoad( layer3, ivec2(xp,yp+offset)).r; break;
		case 4:return_value=imageLoad( layer3, ivec2(xp,yp+offset)).r; break;
		case 5:return_value=imageLoad( layer3, ivec2(xp,yp+offset)).r; break;
		case 6:return_value=imageLoad( layer3, ivec2(xp,yp+offset)).r; break;
		case 7:return_value=imageLoad( layer3, ivec2(xp,yp+offset)).r; break;
	}
	return return_value;
}

//write float value from image2d
void write_array(int xp, int yp, int which_layer, float value) {
	//The offset calculation determines if the top of bottom half of the texture
	//should be read from.  this alternates every frame.  The read_array
	//function uses the opposite half so the top half is read when the bottom
	//half is written to.  Then they swap for the next frame.
	int offset=0;
	if (mod(frames,2)<1) { offset=y_res; }
	switch (which_layer) {
		case 1:imageStore( layer1, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 2:imageStore( layer2, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 3:imageStore( layer3, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 4:imageStore( layer4, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 5:imageStore( layer5, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 6:imageStore( layer6, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
		case 7:imageStore( layer7, ivec2(xp,yp+offset), vec4(value,0,0,1)); break;
	}
	
}

///////////////////////////////////////////////////////////////////////////////
// Neighborhood processing
///////////////////////////////////////////////////////////////////////////////

//averages array values over a rectangular neighborhood
float Average_Rectangular_Neighborhood(int range, int which_layer) {
	float f=0.0;
	int range_div=(range*2+1)*(range*2+1);
	for (int y=y_pixel-range;y<=y_pixel+range;y++) {
		for (int x=x_pixel-range;x<=x_pixel+range;x++) {
			int xp=x;
			int yp=y;
			if (xp<0) { xp=xp+x_res; }
			if (xp>=x_res) { xp=xp-x_res; }
			if (yp<0) { yp=yp+y_res; }
			if (yp>=y_res) { yp=yp-y_res; }
			f+=read_array(xp,yp,which_layer);
		}
	}
	f=f/range_div;
	return f;
}

//totals array values over a rectangular neighborhood
float Total_Rectangular_Neighborhood(int range, int which_layer) {
	float f=0.0;
	for (int y=y_pixel-range;y<=y_pixel+range;y++) {
		for (int x=x_pixel-range;x<=x_pixel+range;x++) {
			int xp=x;
			int yp=y;
			if (xp<0) { xp=xp+x_res; }
			if (xp>=x_res) { xp=xp-x_res; }
			if (yp<0) { yp=yp+y_res; }
			if (yp>=y_res) { yp=yp-y_res; }
			f+=read_array(xp,yp,which_layer);
		}
	}
	return f;
}

//averages array values over a circular neighborhood
float Average_Circular_Neighborhood(int range, int which_layer) {
	float f=0.0;
	int count=0;
	int range_div=(range*2+1)*(range*2+1);
	for (int y=y_pixel-range;y<y_pixel+range;y++) {
		for (int x=x_pixel-range;x<x_pixel+range;x++) {
			if (sqrt(((x-x_pixel)*(x-x_pixel))+((y-y_pixel)*(y-y_pixel)))<range) {
				int xp=x;
				int yp=y;
				if (xp<0) { xp=xp+x_res; }
				if (xp>=x_res) { xp=xp-x_res; }
				if (yp<0) { yp=yp+y_res; }
				if (yp>=y_res) { yp=yp-y_res; }
				f+=read_array(xp,yp,which_layer);
				count++;
			}
		}
	}
	f=f/count;
	return f;
}

//totals array values over a circular neighborhood
float Total_Circular_Neighborhood(int range, int which_layer) {
	float f=0.0;
	for (int y=y_pixel-range;y<y_pixel+range;y++) {
		for (int x=x_pixel-range;x<x_pixel+range;x++) {
			if (sqrt(((x-x_pixel)*(x-x_pixel))+((y-y_pixel)*(y-y_pixel)))<range) {
				int xp=x;
				int yp=y;
				if (xp<0) { xp=xp+x_res; }
				if (xp>=x_res) { xp=xp-x_res; }
				if (yp<0) { yp=yp+y_res; }
				if (yp>=y_res) { yp=yp-y_res; }
				f+=read_array(xp,yp,which_layer);
			}
		}
	}
	return f;
}

///////////////////////////////////////////////////////////////////////////////
// Yin-Yang Fire https://softologyblog.wordpress.com/2015/01/30/yin-yang-fire/
///////////////////////////////////////////////////////////////////////////////

//yin yang fire neighborhood
float YYF_Neighborhood(int range, int which_layer) {
    //float numstates=128;
    //float plus_value=2.0/numstates;
    
	float numstates=1.0;

    float plus_value=0.05;
	float bump_value=0.005;
	float f=Total_Rectangular_Neighborhood(range,which_layer);
	int range_div=(range*2+1)*(range*2+1);
	
    float count=f;
    //update cell
	float result=read_array(x_pixel,y_pixel,which_layer);
    float me = result;
    if (me*range_div+plus_value>=count) {
		result=result-bump_value;
		if (result<0.0) { 
			result=numstates-bump_value; 
		}
    } else {
		result=me+bump_value;
        }	
	return result;
}

///////////////////////////////////////////////////////////////////////////////
// Main function
///////////////////////////////////////////////////////////////////////////////

void main()
{
	//current pixel being written to
	x_pixel=int(gl_FragCoord.x);
	y_pixel=int(gl_FragCoord.y);
	//current image x and y resolution in pixels
	x_res=int(resolution.x);
	y_res=int(resolution.y);
	
	//initially draw the white square pixels
    if(frames<2) {
		vec4 col;
		
		//centered gray square
		//if ((abs(x_res/2-x_pixel)<100)&&(abs(y_res/2-y_pixel)<100)) { col=vec4(0.5,0.5,0.5,1.0); } else { col=vec4(0.0,0.0,0.0,1.0); }
		
		//random noise for each layer
		//random noise from the passed randomlcg Image2D array/texture
		write_array(x_pixel,y_pixel,1,random_lcg(vec2(x_pixel,y_pixel),17));
		write_array(x_pixel,y_pixel,2,random_lcg(vec2(x_pixel,y_pixel),18));
		write_array(x_pixel,y_pixel,3,random_lcg(vec2(x_pixel,y_pixel),19));

		gl_FragColor=col;
	} else {
		float f,r,g,b;
			
		//Yin-Yang Fire
		layer1_result=YYF_Neighborhood(3,1);
		layer2_result=YYF_Neighborhood(3,2);
		layer3_result=YYF_Neighborhood(3,3);

		write_array(x_pixel,y_pixel,1,layer1_result);
		write_array(x_pixel,y_pixel,2,layer2_result);
		write_array(x_pixel,y_pixel,3,layer3_result);

		//display RGB values based on layer values
		r=layer1_result;
		g=layer2_result;
		b=layer3_result;
		
		vec3 output_rgb=vec3(0.0);
		
		//gives the values a sin upwards curve rather than straight line between 0 and 1
		r=sin(r*3.1415/2.0);
		g=sin(g*3.1415/2.0);
		b=sin(b*3.1415/2.0);
		
		output_rgb=vec3(r,g,b);
		//output_rgb=vec3(hsv2rgb(vec3(r,g,min((r+g+b)/2,1.0)/2.0+0.5)));
		//output_rgb=vec3(hsv2rgb(vec3(r,g,b)));
		//output_rgb=vec3(hsv2rgb(vec3(r,g,max(r,max(g,b)))));
		//output_rgb=vec3(hsv2rgb(vec3((r+g+b)/3.0,max(r,max(g,b))/2.0,min((r+g+b)/2.0,1.0))));
		//output_rgb=vec3(min((r+g)*0.7,1.0),min((g+b)*0.7,1.0),min((r+b)*0.7,1.0));
		//output_rgb=vec3((r+g)/2,(g+b)/2,(b+r)/2);
		
		//contrast(output_rgb,1.5);
		
		//update display
		gl_FragColor=vec4(output_rgb,1.0);
		
	}
	
}

