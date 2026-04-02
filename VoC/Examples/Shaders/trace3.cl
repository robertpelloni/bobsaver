struct Ray{
	double3 origin;
	double3 dir;
};

struct Sphere{
	double radius;
	double3 pos;
	double3 emi;
	double3 color;
};

double sphIntersect( double3 ro, double3 rd, double4 sph )
{
    double3 oc = ro - sph.xyz;
    double b = dot( oc, rd );
    double c = dot( oc, oc ) - sph.w*sph.w;
    double h = b*b - c;
    if( h<0.0 ) return -1.0;
    h = sqrt( h );
    return -b - h;
}

bool intersect_sphere(const struct Sphere* sphere, const struct Ray* ray, double* t)
{
	double3 rayToCenter = sphere->pos - ray->origin;

	/* calculate coefficients a, b, c from quadratic equation */

	/* double a = dot(ray->dir, ray->dir); // ray direction is normalised, dotproduct simplifies to 1 */ 
	double b = dot(rayToCenter, ray->dir);
	double c = dot(rayToCenter, rayToCenter) - sphere->radius*sphere->radius;
	double disc = b * b - c; /* discriminant of quadratic formula */

	/* solve for t (distance to hitpoint along ray) */

	if (disc < 0.0) return false;
	else *t = b - sqrt(disc);

	if (*t < 0.0){
		*t = b + sqrt(disc);
		if (*t < 0.0) return false; 
	}

	else return true;
}

struct Ray createCamRay(const int x_coord, const int y_coord, const int width, const int height){

	double fx = (double)x_coord / (double)width;  /* convert int in range [0 - width] to double in range [0-1] */
	double fy = (double)y_coord / (double)height; /* convert int in range [0 - height] to double in range [0-1] */

	/* calculate aspect ratio */
	double aspect_ratio = (double)(width) / (double)(height);
	double fx2 = (fx - 0.5) * aspect_ratio;
	double fy2 = fy - 0.5;

	/* determine position of pixel on screen */
	double3 pixel_pos = (double3)(fx2, -fy2, 0.0);

	/* create camera ray*/
	struct Ray ray;
	ray.origin = (double3)(0.0, 0.0, 40.0); /* fixed camera position */
	ray.dir = normalize(pixel_pos - ray.origin); /* ray direction is vector from camera to pixel */

	return ray;
}

//kernel entry point - the "main" function
//Visions of Chaos passes all these variables and arrays into the kernel
__kernel void pixel_kernel( __global uchar* r,            //red component of pixel color passed in and back out
							__global uchar* g,            //green component of pixel color passed in and back out
							__global uchar* b,            //blue component of pixel color passed in and back out
							__global uchar* a,            //alpha component of pixel color passed in and back out
							__global int* width,          //image width
							__global int* height,         //image height
							__global double* camerax,     //camera eye x position
							__global double* cameray,     //camera eye y position 
							__global double* cameraz,     //camera eye z position
							__global double* targetx,     //camera lookat x position
							__global double* targety,     //camera lookat y position
							__global double* targetz,     //camera lookat z position
							__global double* rotationx,   //camera x rotation
							__global double* rotationy,   //camera y rotation
							__global double* rotationz,   //camera z rotation
							__global double* fov,         //camera field of view
							__global double* ambientr,    //ambient light red component
							__global double* ambientg,    //ambient light green component
							__global double* ambientb,    //ambient light blue component
							__global double* lightx,      //light x positions
							__global double* lighty,      //light y positions
							__global double* lightz,      //light z positions
							__global double* lightr,      //light color red component
							__global double* lightg,      //light color green component
							__global double* lightb,      //light color blue component
							__global int* numlights,      //total number of lights
							__global double* cellsx,      //active cells x positions
							__global double* cellsy,      //active cells y positions
							__global double* cellsz,      //active cells z positions
							__global int* numcells        //total number of cells to render
							)
{
	//local variables
	double3 N,T,B,L,rO,rD,Ntmp,lookat,eye;
	double aspect,alpha,beta,amin,amax,bmin,bmax,awidth,bheight,xstep,ystep,pidiv180;
	
	//index of the current work item for the current pixel
	const int work_item_id = get_global_id(0);
	
	//x and y coordinates
	int x_coord = work_item_id % width[0];
	int y_coord = work_item_id / width[0];
	
	//x and y coordinates scaled to the range 0 to 1
	double fx = (double)x_coord / (double)width[0];
	double fy = (double)y_coord / (double)height[0];

	eye = (double3)(camerax[0],cameray[0],cameraz[0]);
	lookat = (double3)(targetx[0],targety[0],targetz[0]);
	double3 up = (double3)(0.0,1.0,0.0);
	pidiv180 = 3.1415/180.0;
	
	//construct the basis
	N=normalize(lookat-eye);
	T=normalize(up);
	B=cross(N,T);
    aspect=width[0]/height[0];
    beta=tan(fov[0]*pidiv180)/2.0;
    alpha=beta*aspect;
    amin=-alpha;
    amax=alpha;
    bmin=-beta;
    bmax=beta;
    awidth=amax-amin;
    bheight=bmax-bmin;
    xstep=awidth/width[0];
    ystep=bheight/height[0];


	double3 output=(double3)(0.0,0.0,0.0);
	int rendermode=6;

	/*create a camera ray */
	struct Ray camray = createCamRay(x_coord, y_coord, width[0], height[0]);

	camray.origin = (double3)(camerax[0],cameray[0],cameraz[0]);
	
	double t = 100000;
	struct Sphere sphere1;
	/* create and initialise a sphere */
	sphere1.radius = 0.1;
	sphere1.color = (double3)(0.9, 0.9, 0.9);
	
	int n = (int)numcells[0];
	for(int i=0; i<n; i++) {
		sphere1.pos = (double3)(cellsx[i],cellsy[i],cellsz[i]);
		intersect_sphere(&sphere1, &camray, &t);
	}
	
	/* if ray misses sphere, return background colour 
	background colour is a blue-ish gradient dependent on image height */
	if (t > 10000 && rendermode != 1){ 
		output = (double3)(fy * 0.1, fy * 0.3, 0.3);
		output = (double3)(ambientr[0],ambientg[0],ambientb[0]);
		r[work_item_id]=(uchar)(output.s0*255);
		g[work_item_id]=(uchar)(output.s1*255);
		b[work_item_id]=(uchar)(output.s2*255);
		a[work_item_id]=255;	
		return;
	}

	/* for more interesting lighting: compute normal 
	and cosine of angle between normal and ray direction */
	double3 hitpoint = camray.origin + camray.dir * t;
	double3 normal = normalize(hitpoint - sphere1.pos);
	double cosine_factor = dot(normal, camray.dir) * -1.0;
	
	output = sphere1.color * cosine_factor;

	/* six different rendermodes */
	if (rendermode == 1) output = (double3)(fx, fy, 0); /* simple interpolated colour gradient based on pixel coordinates */
	else if (rendermode == 2) output = sphere1.color;  /* raytraced sphere with plain colour */
	else if (rendermode == 3) output = sphere1.color * cosine_factor; /* with cosine weighted colour */
	else if (rendermode == 4) output = sphere1.color * cosine_factor * sin(80 * fy); /* with sinusoidal stripey pattern */
	else if (rendermode == 5) output = sphere1.color * cosine_factor * sin(400 * fy) * sin(400 * fx); /* with grid pattern */
	else output = normal * (double)0.5 + (double3)(0.5, 0.5, 0.5); /* with normal colours */
	
	r[work_item_id]=(uchar)(output.s0*255);
	g[work_item_id]=(uchar)(output.s1*255);
	b[work_item_id]=(uchar)(output.s2*255);
	a[work_item_id]=255;	
}