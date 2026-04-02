#version 420

// original https://www.shadertoy.com/view/tdt3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Blog post for DE function of a julia set by Inigo Quilez;
// https://www.iquilezles.org/www/articles/distancefractals/distancefractals.htm

// Quick little function to multiply two quaternions.
// The proof is left as an exercise to the reader
vec4 MultiplyQuaternions(vec4 a, vec4 b)
{
    float real = a.w*b.w - dot(a.xyz, b.xyz);  
    vec3 complex = (a.w*b.xyz + b.w*a.xyz + cross(a.xyz, b.xyz));
    return vec4(complex, real);
}

// Convert degrees to radians
float Radians(float deg)
{
     return deg / 360.0 * 2.0 * 3.14159; 
}

// Write a float4 function for some of the HLSL Code conversion
vec4 float4(float x, float y, float z, float w)
{
     return vec4(x,y,z,w);   
}

// Write a float3 function for the same purpose
vec3 float3(float x, float y, float z)
{
     return vec3(x,y,z);   
}

// Exact SDF for a sphere
float dSphere(vec3 pos, vec3 center, float radius)
{
    // find the distance to the center
    vec3 v = pos - center;
    
    // return that, minus the radius
    return length(v) - radius;
}

// Exact intersection of a sphere. Resolves a quatratic equation. Returns the 
// min distance, max distance, and discriminant to determine if the intersections
// actually exist.
vec3 intersections_of_sphere(vec3 pos_vector, vec3 dir_vector, float sphere_radius)
{
    // Derivation for formula:
    //        Let the ray be represented as a point P plus a scalar multiple t of the direction vector v,
    //        The ray can then be expressed as P + vt
    //
    //        The point of intersection I = (x, y, z) must be expressed as this, but must also be some distance r
    //        from the center of the sphere, thus x*x + y*y + z*z = r*r, or in vector notation, I*I = r*r
    //
    //        It therefore follows that (P + vt)*(P + vt) = r*r, or when expanded and rearranged,
    //        (v*v)t^2 + (2P*v)t + (P*P - r*r) = 0. For this we will use the quadratic equation for the points of
    //        intersection

    // a, b, and c correspond to the second, first, and zeroth order terms of t, the parameter we are trying to solve for.
    float a = dot(dir_vector, dir_vector);
    float b = 2.0 * dot(pos_vector, dir_vector);
    float c = dot(pos_vector, pos_vector) - sphere_radius * sphere_radius;

    // to avoid imaginary number, we will find the absolute value of the discriminant.
    float discriminant = b * b - 4.0 * a*c;
    float abs_discriminant = abs(discriminant);
    float min_dist = (-b - sqrt(abs_discriminant)) / (2.0 * a);
    float max_dist = (-b + sqrt(abs_discriminant)) / (2.0 * a);

    // return the two intersections, along with the discriminant to determine if
    // the intersections actually exist.
    return float3(min_dist, max_dist, discriminant);

}

// Distance estimation for a julia set.
float DE(vec3 p, vec3 c, vec4 seed)
{
    // First, offset the point by the center
    vec3 v = p - c;

    // Set C to be a vector of constants determining julia set we use
    vec4 C = seed;
    
    // Set Z to be some form of input from the vector
    vec4 Z = float4(v.z, v.y, 0.0, v.x);
    
    // I'll be honest, I'm not entirely sure how the distance estimation works.
    // Calculate the derivative of Z. The Julia set we are using is Z^2 + C,
    // So this results in simply 2z
    vec4 dz = 2.0*Z + vec4(1.0, 1.0, 1.0, 1.0);

    // Run the iterative loop for some number of iterations
    for (int i = 0; i < 64; i++)
    {
        // Recalculate the derivative
        dz = 2.0 * MultiplyQuaternions(Z, dz) + vec4(1.0, 1.0, 1.0, 1.0);
        
        // Rcacalculate Z
        Z = MultiplyQuaternions(Z, Z) + C;
        
           // We rely on the magnitude of z being fairly large (the derivation includes
        // A limit as it approaches infinity) so we're going to let it run for a bit longer
        // after we know its going to explode. i.e. 1000 instead of the usual, like 8.
        if (dot(Z, Z) > 1000.0)
        {
            break;
            }
        }
    
    // And this is where the witchcraft happens. Again, not sure how this works, but as
       // you can see, it does.
    float d = 0.5*sqrt(dot(Z, Z) / dot(dz, dz))*log(dot(Z, Z)) / log(10.0);
    
    // Return the distance estimation.
    return d;

}

void main(void)
{
    // Define the iterations for the marcher.
    const int ITERATIONS = 200;
    
    // Define the roation speed. Set to 0 to disable
    const float ROTATION_SPEED = 0.6;
    
    // Define the start angle for the rotation (in degrees)
    const float START_ANGLE = 0.0;
    
    // Define the orbit radius
    const float ORBIT_RADIUS = 2.5;
    
    // Define the epsilon value for closeness to be considered a hit
    const float EPSILON = 0.0001;
    
    // Define if we should invert the color at the end
    const bool DARK_MODE = false;
    
    
    // Define the specific julia set being marched. Below are a couple different seeds
    // I found to be interesting. Just uncomment the ones you want to see
    
    //vec4 julia_seed = vec4(0.0, -0.2, 0.0, -1.17);
    //vec4 julia_seed = vec4(0.2, 0.67, 0.0, -0.5);
    vec4 julia_seed = vec4(0.33, 0.56, 0.0, -0.72);    
    //vec4 julia_seed = vec4(-0.15, -0.15, 0.0, -.95);
    
    // Define the center of the julia set
    vec3 julia_center = vec3(0.0, 0.0, 0.0);
 
    // Calculate the starting angles for the orbit
    float theta = time * ROTATION_SPEED;
    float phi = Radians(START_ANGLE);
    
    // Define an orbital path based on time
    vec3 orbit = vec3(cos(theta)*cos(phi), sin(phi), sin(theta)*cos(phi));
    
    // Cacluate the normal of the path. Since its a circle, it will just
    // be back down into the center
    vec3 normal = -normalize(orbit);
    
    // Calculate the tangent of the path
    // A circle consists of <cost, sint>, which when differentiated yields
    // <-sint, cost>. since z is already sint, and x is already cost, the equation
    // is as follows.
    vec3 tangent = normalize(vec3(-normal.z, 0.0, normal.x));
    
    // Calculate the UV coordinates
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    // Convert the UV coordinates to a range between -1 and 1
    vec2 range = uv*2.0 - vec2(1.0,1.0);
    
    //// Define the Camera position
    //vec3 cam_pos = vec3(0,0,-2);
    
    //// Define the forward, up, and right vectors (needs rework)
    //vec3 forward = normalize(vec3(0,0,1));
    //vec3 up = normalize(vec3(0,1,0));
    //vec3 right = normalize(vec3(1,0,0));
    
    // Define the Camera position
    vec3 cam_pos = orbit*ORBIT_RADIUS;
    
    // Define the forward, up, and right vectors (needs rework)
    vec3 forward = normal;
    vec3 up = normalize(cross(normal, tangent));
    vec3 right = tangent;
        
    // Calculate the aspect ratio of the screen
    float aspect = float(resolution.y) / float(resolution.x);
    
    // Calculate the ray as a normalized combination of the forward, right, and up vectors.
    // Note that the purely forward + horizonal combination yield vectors 45 degrees outward
    // for a 90 degree field of view. This may be updated with a fov option
    vec3 ray = normalize(forward + range.x*right + range.y*up*aspect);
    
    // Initialize the ray marched point p
    vec3 p = cam_pos;

    // Initialize the distance
    float dist = 1.0;
    
    // Calculate the exact distance from a sphere of radius 2 using a raytracing function
    vec3 init_distance = intersections_of_sphere(p - julia_center, ray, 2.0);
    
    // If we are outside a bubble around the raymarched fractal
    if (init_distance.z > 0.0)
    {
        // Step onto the sphere so we start off a bit closer.
        p += ray * clamp(init_distance.x, 0.0, init_distance.x);
    }

    // declare a dummy variable to store the number of iterations into.
    // I'm doing it this way because on my phone it didnt let me use an
    // already declared variable as the loop iterator.
    int j;
    
    
    // Begin the raymarch
    for (int i = 0; i < ITERATIONS; i++)
    {
        // Estimate the distance to the julia set
        dist = DE(p, julia_center, julia_seed);
        
        // Move forward that distance
        p += ray*dist;
        
        // Record the number of iterations we are on
        j = i;
        
        // If we hit the julia set, or get too far away form it
        if (dist < EPSILON || dot(p - julia_center, p-julia_center) > 8.1)
        {
            // Break the loop.
            break;   
        }
        
    }
    
    // calculate the brightness based on iterations used
    float di = float(j) / float(ITERATIONS);

    
    
    // determine if we hit the fractal or not
    float hit = step(dist, EPSILON);
    
    if (!DARK_MODE)
    {
         di = 1.0 - di;   
    }
    
    // define some phase angle
    float psi = Radians(70.0);
    
    // Time varying pixel color (included in default shadertoy project)
    vec3 col = 0.8 + 0.2*cos(time*0.5+uv.xyx+vec3(0,2,4) + psi*hit);
    
    // Boring old white instead of the above commented code. Will tweak rendering later
    //vec3 col = vec3(0.7,1.0,.93);
    
    
    // Output to screen. Modifiy the color with the brightness calculated as di.
    glFragColor = vec4(col*di,1.0);
}
