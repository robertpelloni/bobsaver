struct Ray{
	float3 origin;
	float3 dir;
};

struct Sphere{
	float radius;
	float3 pos;
	float3 emi;
	float3 color;
};

bool intersect_sphere(const struct Sphere* sphere, const struct Ray* ray, float* t)
{
	float3 rayToCenter = sphere->pos - ray->origin;

	/* calculate coefficients a, b, c from quadratic equation */

	/* float a = dot(ray->dir, ray->dir); // ray direction is normalised, dotproduct simplifies to 1 */ 
	float b = dot(rayToCenter, ray->dir);
	float c = dot(rayToCenter, rayToCenter) - sphere->radius*sphere->radius;
	float disc = b * b - c; /* discriminant of quadratic formula */

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

	float fx = (float)x_coord / (float)width;  /* convert int in range [0 - width] to float in range [0-1] */
	float fy = (float)y_coord / (float)height; /* convert int in range [0 - height] to float in range [0-1] */

	/* calculate aspect ratio */
	float aspect_ratio = (float)(width) / (float)(height);
	float fx2 = (fx - 0.5) * aspect_ratio;
	float fy2 = fy - 0.5;

	/* determine position of pixel on screen */
	float3 pixel_pos = (float3)(fx2, -fy2, 0.0);

	/* create camera ray*/
	struct Ray ray;
	ray.origin = (float3)(0.0, 0.0, 40.0); /* fixed camera position */
	ray.dir = normalize(pixel_pos - ray.origin); /* ray direction is vector from camera to pixel */

	return ray;
}

__kernel void pixel_kernel( __global uchar* r,
							__global uchar* g,
							__global uchar* b, 
							__global uchar* a,
							__global int* width,
							__global int* height,
							__global float* eyex,
							__global float* eyey, 
							__global float* eyez
							)
{
	const int work_item_id = get_global_id(0);		/* the unique global id of the work item for the current pixel */
	int x_coord = work_item_id % width[0];					/* x-coordinate of the pixel */
	int y_coord = work_item_id / width[0];					/* y-coordinate of the pixel */

	float fx = (float)x_coord / (float)width[0];  /* convert int in range [0 - width] to float in range [0-1] */
	float fy = (float)y_coord / (float)height[0]; /* convert int in range [0 - height] to float in range [0-1] */

	float3 output=(float3)(0.0,0.0,0.0);
	int rendermode=6;

	//eye.s0=(float)(eyex[0]);
	//eye.s1=(float)(eyey[0]);
	//eye.s2=(float)(eyez[0]);
	//struct cam Camera;
	//cam.pos=(float3)(eyex[0],eyey[0],eyez[0]);

	/*create a camera ray */
	struct Ray camray = createCamRay(x_coord, y_coord, width[0], height[0]);

	camray.origin = (float3)(eyex[0],eyey[0],eyez[0]);

	/* create and initialise a sphere */
	struct Sphere sphere1;
	sphere1.radius = 0.4;
	sphere1.pos = (float3)(0.0, 0.0, 3.0);
	sphere1.color = (float3)(0.9, 0.3, 0.0);

	/* intersect ray with sphere */
	float t = 100000;
	intersect_sphere(&sphere1, &camray, &t);

	/* if ray misses sphere, return background colour 
	background colour is a blue-ish gradient dependent on image height */
	if (t > 10000 && rendermode != 1){ 
		output = (float3)(fy * 0.1, fy * 0.3, 0.3);
	r[work_item_id]=(uchar)(output.s0*255);
	g[work_item_id]=(uchar)(output.s1*255);
	b[work_item_id]=(uchar)(output.s2*255);
	a[work_item_id]=255;	
		return;
	}

	/* for more interesting lighting: compute normal 
	and cosine of angle between normal and ray direction */
	float3 hitpoint = camray.origin + camray.dir * t;
	float3 normal = normalize(hitpoint - sphere1.pos);
	float cosine_factor = dot(normal, camray.dir) * -1.0;
	
	output = sphere1.color * cosine_factor;

	/* six different rendermodes */
	if (rendermode == 1) output = (float3)(fx, fy, 0); /* simple interpolated colour gradient based on pixel coordinates */
	else if (rendermode == 2) output = sphere1.color;  /* raytraced sphere with plain colour */
	else if (rendermode == 3) output = sphere1.color * cosine_factor; /* with cosine weighted colour */
	else if (rendermode == 4) output = sphere1.color * cosine_factor * sin(80 * fy); /* with sinusoidal stripey pattern */
	else if (rendermode == 5) output = sphere1.color * cosine_factor * sin(400 * fy) * sin(400 * fx); /* with grid pattern */
	else output = normal * (float)0.5 + (float3)(0.5, 0.5, 0.5); /* with normal colours */
	
	r[work_item_id]=(uchar)(output.s0*255);
	g[work_item_id]=(uchar)(output.s1*255);
	b[work_item_id]=(uchar)(output.s2*255);
	a[work_item_id]=255;	
}