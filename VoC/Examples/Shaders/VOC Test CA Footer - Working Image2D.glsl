//image2D that act as 32 bit single precision 2D arrays for passing data to/from Visions of Chaos
//each array is 2 Image2Ds for reading and writing to which are swapped each frame otherwise memory corruption occurs
layout (binding=0,r32f) uniform image2D random_lcg;
layout (binding=1,r32f) uniform image2D layer1a;
layout (binding=2,r32f) uniform image2D layer1b;
layout (binding=3,r32f) uniform image2D layer2a;
layout (binding=4,r32f) uniform image2D layer2b;
layout (binding=5,r32f) uniform image2D layer3a;
layout (binding=6,r32f) uniform image2D layer3b;

int x_pixel,y_pixel,xp,yp,x_res,y_res,range,range_div;
float layer1_result,layer2_result,layer3_result;

///////////////////////////////////////////////////////////////////////////////
// Random function
///////////////////////////////////////////////////////////////////////////////

//random function - returns a float between 0 and 1
float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

///////////////////////////////////////////////////////////////////////////////
// Color conversions
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

vec3 contrastRGB(vec3 c, float contrast) {
	float red,green,blue,newred,newgreen,newblue;
	red=c.r;
	green=c.g;
	blue=c.b;
	newred=red;
	newgreen=green;
	newblue=blue;
	if (contrast!=0) {
		red=red+int(red-0.5)*contrast/100.0;
		green=green+int(green-0.5)*contrast/100.0;
		blue=blue+int(blue-0.5)*contrast/100.0;
		newred=min(1.0,max(newred,0));
		newgreen=min(1.0,max(newgreen,0));
		newblue=min(1.0,max(newblue,0));
	}
	return vec3(newred,newgreen,newblue);
}

///////////////////////////////////////////////////////////////////////////////
// Functions to read/write float values from/to the passed Image2D r32f arrays
// Because you cannot read and write to the same arrays at the same time these
// functions swap between the a and b arrays every other frame.  This also
// saves having to "ping pong" fbos outside the shader.
///////////////////////////////////////////////////////////////////////////////

//read float value from image2d
float read_array(int xp, int yp, int which_layer) {
	float return_value=0;
	switch (int(mod(frames,2))) {
		case 0:	switch (which_layer) {
					case 1:return_value=imageLoad( layer1a, ivec2(xp,yp) ).r; break;
					case 2:return_value=imageLoad( layer2a, ivec2(xp,yp) ).r; break;
					case 3:return_value=imageLoad( layer3a, ivec2(xp,yp) ).r; break;
				} break;
		case 1:	switch (which_layer) {
					case 1:return_value=imageLoad( layer1b, ivec2(xp,yp) ).r; break;
					case 2:return_value=imageLoad( layer2b, ivec2(xp,yp) ).r; break;
					case 3:return_value=imageLoad( layer3b, ivec2(xp,yp) ).r; break;
				} break;
	}
	return return_value;
}

//write float value from image2d
void write_array(int xp, int yp, int which_layer, float value) {
	switch (int(mod(frames,2))) {
		case 0:	switch (which_layer) {
					case 1:imageStore( layer1b, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
					case 2:imageStore( layer2b, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
					case 3:imageStore( layer3b, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
				} break;
		case 1:	switch (which_layer) {
					case 1:imageStore( layer1a, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
					case 2:imageStore( layer2a, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
					case 3:imageStore( layer3a, ivec2(gl_FragCoord.xy), vec4(value,0,0,1)); break;
				} break;
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
	
    //float plus_value=0.01;
	//float bump_value=0.005;
	//float f=Total_Circular_Neighborhood(range,which_layer);
	
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
		col=vec4(vec3(random(gl_FragCoord.xy/resolution.xy)),1.0);		
		write_array(x_pixel,y_pixel,1,col.r);
		col=vec4(vec3(random(gl_FragCoord.xy/resolution.xy+1.0)),1.0);		
		write_array(x_pixel,y_pixel,2,col.r);
		col=vec4(vec3(random(gl_FragCoord.xy/resolution.xy+2.0)),1.0);		
		write_array(x_pixel,y_pixel,3,col.r);

		gl_FragColor=col;
	} else {
		float f,r,g,b;
		
		/**
		//blur the pixels
		f=Average_Circular_Neighborhood(11,1);
		//f=f+0.005; if (f>1.0) { f=f-1.0; } if (f<0.0) { f=f+1.0; }
		layer1_result=f;
		f=Average_Circular_Neighborhood(15,2);
		//f=f+0.005; if (f>1.0) { f=f-1.0; } if (f<0.0) { f=f+1.0; }
		layer2_result=f;
		f=Average_Circular_Neighborhood(19,3);
		//f=f+0.005; if (f>1.0) { f=f-1.0; } if (f<0.0) { f=f+1.0; }
		layer3_result=f;
		
		//bump the layer values towards smaller other layer
		if (layer1_result<layer2_result) { layer1_result+=0.01; } else { layer1_result-=0.01; }
		if (layer2_result<layer3_result) { layer2_result+=0.01; } else { layer2_result-=0.01; }
		if (layer3_result<layer1_result) { layer3_result+=0.01; } else { layer3_result-=0.01; }
		
		layer1_result+=0.001;
		if (layer1_result>1.0) { layer1_result=1.0-layer1_result; }
		layer2_result+=0.001;
		if (layer2_result>1.0) { layer2_result=1.0-layer2_result; }
		layer3_result+=0.001;
		if (layer3_result>1.0) { layer3_result=1.0-layer3_result; }
		**/
		
	
		//Yin-Yang Fire
		layer1_result=YYF_Neighborhood(3,1);
		layer2_result=YYF_Neighborhood(4,2);
		layer3_result=YYF_Neighborhood(5,3);
	
	
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
		
		//update display
		output_rgb=vec3(r,g,b);
		//output_rgb=vec3(hsv2rgb(vec3(r,g,min((r+g+b)/2,1.0)/2.0+0.5)));
		//output_rgb=vec3(hsv2rgb(vec3(r,g,b)));
		//output_rgb=vec3(hsv2rgb(vec3((r+g+b)/3.0,max(r,max(g,b))/2.0,min((r+g+b)/2.0,1.0))));
		//output_rgb=vec3(yuv2rgb(vec3(r,g,b)));
		//output_rgb=vec3(min((r+g),1.0),min((g+b),1.0),min((r+b),1.0));
		
		output_rgb=contrastRGB(output_rgb,125);
		
		gl_FragColor=vec4(output_rgb,1.0);
		
	}
	
}
