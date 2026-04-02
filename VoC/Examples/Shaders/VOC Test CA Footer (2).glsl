//image2D that act as 32 bit single precision 2D arrays for passing data to/from Visions of Chaos
//layout (binding=1,r32f) uniform image2D layer1;
//layout (binding=2,r32f) uniform image2D layer2;
//layout (binding=3,r32f) uniform image2D layer3;

//trying to get memory to be correct
//this from https://cs.brown.edu/courses/csci1950-v/lecture/week6.pdf
coherent restrict uniform layout(binding=1,r32f) image2D layer1;
coherent restrict uniform layout(binding=2,r32f) image2D layer2;
coherent restrict uniform layout(binding=3,r32f) image2D layer3;

int x_pixel,y_pixel,xp,yp,x_res,y_res,range,range_div;
float layer1_result,layer2_result,layer3_result;

//////////////////////////////////////////////////////////////////////
uint seed = 0u;
void hash(){
    seed ^= 2747636419u;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
}
void initRandomGenerator(vec2 uv){
    seed = uint(uv.y*resolution.x + uv.x)+uint(time*6000000.0);
}

float random2(){
    hash();
    return float(seed)/4294967295.0;
}
/////////////////////////////////////////////////////////////////////

//random function - returns a float between 0 and 1
float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//rectangular neighborhood
float Rectangular_Neighborhood(int range, int which_layer) {
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
			switch (which_layer) {
				case 1:f+=imageLoad( layer1, ivec2(xp,yp) ).r; break;
				case 2:f+=imageLoad( layer2, ivec2(xp,yp) ).r; break;
				case 3:f+=imageLoad( layer3, ivec2(xp,yp) ).r; break;
			}
		}
	}
	f=f/range_div;
	//return f;
	return imageLoad( layer1, ivec2(xp,yp) ).r+0.001;
}

//circular neighborhood
float Circular_Neighborhood(int range, int which_layer) {
	float f=0.0;
	int count=0;
	int range_div=(range*2+1)*(range*2+1);
	for (int y=y_pixel-range;y<=y_pixel+range;y++) {
		for (int x=x_pixel-range;x<=x_pixel+range;x++) {
			if (sqrt(((x-x_pixel)*(x-x_pixel))+((y-y_pixel)*(y-y_pixel)))<range) {
				int xp=x;
				int yp=y;
				if (xp<0) { xp=xp+x_res; }
				if (xp>=x_res) { xp=xp-x_res; }
				if (yp<0) { yp=yp+y_res; }
				if (yp>=y_res) { yp=yp-y_res; }
				switch (which_layer) {
				case 1:f+=imageLoad( layer1, ivec2(xp,yp) ).r; break;
				case 2:f+=imageLoad( layer2, ivec2(xp,yp) ).r; break;
				case 3:f+=imageLoad( layer3, ivec2(xp,yp) ).r; break;
				}
				count++;
			}
		}
	}
	f=f/count;
	return f;
}

//yin yang fire neighborhood
float YYF_Neighborhood(int range, int which_layer) {
    //float numstates=128;
    //float plus_value=2.0/numstates;
    float numstates=1.0;
    float plus_value=0.05;
	float bump_value=0.005;
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
			switch (which_layer) {
				case 1:f+=imageLoad( layer1, ivec2(xp,yp) ).r; break;
				case 2:f+=imageLoad( layer2, ivec2(xp,yp) ).r; break;
				case 3:f+=imageLoad( layer3, ivec2(xp,yp) ).r; break;
			}
		}
	}

	float count=f;
    //update cell
	float result;
	switch (which_layer) {
		case 1:result=imageLoad( layer1, ivec2(x_pixel,y_pixel) ).r; break;
		case 2:result=imageLoad( layer2, ivec2(x_pixel,y_pixel) ).r; break;
		case 3:result=imageLoad( layer3, ivec2(x_pixel,y_pixel) ).r; break;
	}
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

void main()
{
	
	//first few frames are random static to seed the CA
    if(frames<2) {
		initRandomGenerator(gl_FragCoord.xy);
		vec4 col;
		//vec4 col=vec4(random(gl_FragCoord.xy/resolution.xy),random(gl_FragCoord.xy/resolution.xy),random(gl_FragCoord.xy/resolution.xy),1.0);
		//vec4 col=vec4(vec3(random2()),1.0);
		if ((gl_FragCoord.x<100)&&(gl_FragCoord.y<100)) { col=vec4(1.0,1.0,1.0,1.0); }
		gl_FragColor=col;
 		imageStore( layer1, ivec2(gl_FragCoord.xy), vec4(col.r,0,0,1));
		imageStore( layer2, ivec2(gl_FragCoord.xy), vec4(col.r,0,0,1));
		imageStore( layer3, ivec2(gl_FragCoord.xy), vec4(col.r,0,0,1));
	} else {

		x_pixel=int(gl_FragCoord.x);
		y_pixel=int(gl_FragCoord.y);
		x_res=int(resolution.x);
		y_res=int(resolution.y);
		float f,r,g,b;

		//Yin-Yang Fire
		//layer1
		//layer1_result=YYF_Neighborhood(3,1);
		//layer2
		//layer2_result=YYF_Neighborhood(1,2);
		//layer3
		//layer3_result=YYF_Neighborhood(1,3);

		
		//rug/blur
		//layer1
		f=Rectangular_Neighborhood(3,1);
		f=f+0.005;
		if (f>1.0) { f=f-1.0; }
		if (f<0.0) { f=f+1.0; }
		layer1_result=f;

		//layer2
		f=Rectangular_Neighborhood(3,2);
		f=f+0.005;
		if (f>1.0) { f=f-1.0; }
		if (f<0.0) { f=f+1.0; }
		layer2_result=f;

		//layer3
		f=Rectangular_Neighborhood(3,3);
		f=f+0.005;
		if (f>1.0) { f=f-1.0; }
		if (f<0.0) { f=f+1.0; }
		layer3_result=f;
		
		//layer1_result=imageLoad( layer1, ivec2(x_pixel,y_pixel) ).r;
		//layer2_result=imageLoad( layer2, ivec2(x_pixel,y_pixel) ).r;
		//layer3_result=imageLoad( layer3, ivec2(x_pixel,y_pixel) ).r;
		
		imageStore( layer1, ivec2(x_pixel,y_pixel), vec4(layer1_result,0,0,1));
		imageStore( layer2, ivec2(x_pixel,y_pixel), vec4(layer2_result,0,0,1));
		imageStore( layer3, ivec2(x_pixel,y_pixel), vec4(layer3_result,0,0,1));

		//display RGB values based on layer values

		//r=min(layer1_result,layer2_result);
		//g=min(layer2_result,layer3_result);
		//b=(layer1_result+layer2_result+layer3_result)/3.0;

		//r=(layer1_result+layer2_result)/2.0;
		//g=(layer2_result+layer3_result)/2.0;
		//b=(layer1_result+layer3_result)/2.0;

		r=layer1_result;
		g=layer2_result;
		b=layer3_result;
		
		//update display
		gl_FragColor=vec4(r,g,b,1.0);
	}
	
}
