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

__kernel void pixel_kernel( __global uchar* r,
							__global uchar* g,
							__global uchar* b, 
							__global uchar* a,
							__global int* width,
							__global int* height,
							__global double* eyex,
							__global double* eyey, 
							__global double* eyez
							)
{
	const int work_item_id = get_global_id(0);		/* the unique global id of the work item for the current pixel */
	int x_coord = work_item_id % width[0];					/* x-coordinate of the pixel */
	int y_coord = work_item_id / width[0];					/* y-coordinate of the pixel */

	double fx = (double)x_coord / (double)width[0];  /* convert int in range [0 - width] to double in range [0-1] */
	double fy = (double)y_coord / (double)height[0]; /* convert int in range [0 - height] to double in range [0-1] */

	double3 output=(double3)(0.0,0.0,0.0);
	int rendermode=6;

	/*create a camera ray */
	struct Ray camray = createCamRay(x_coord, y_coord, width[0], height[0]);

	camray.origin = (double3)(eyex[0],eyey[0],eyez[0]);

	/* create and initialise a sphere */
	struct Sphere sphere1;
	sphere1.radius = 0.8;
	sphere1.pos = (double3)(0.0, 0.0, 3.0);
	sphere1.color = (double3)(0.9, 0.3, 0.0);

	/* intersect ray with sphere */
	double t = 100000;
	intersect_sphere(&sphere1, &camray, &t);

	/* if ray misses sphere, return background colour 
	background colour is a blue-ish gradient dependent on image height */
	if (t > 10000 && rendermode != 1){ 
		output = (double3)(fy * 0.1, fy * 0.3, 0.3);
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