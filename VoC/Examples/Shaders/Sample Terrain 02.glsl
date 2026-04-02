#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//perlin's value noise
float noise(in vec2 uv)
{
        const float k     = 257.;
        vec4 l          = vec4(floor(uv),fract(uv));            //create a low resolution grid (xy) and repeating blend (zw) 
    l.zw            = l.zw*l.zw*(3.-2.*l.zw);            //smooth the values for the repeating blend
    
        float u         = l.x + l.y * k;                    //create an index for each 2d grid position
        vec4 v          = vec4(u, u+1.,u+k, u+k+1.);            //get the 4 indices corrosponding to the 4 neighbor grid points as v.xyzw
        v               = fract(fract(1.23456789*v)*v/.987654321);    //generate a random number for each of the 4 neighbor indices
    
                                    //for the result, mix the random numbers from the grid using the blend 
        l.x             = mix(v.x, v.y, l.z);                //bottom left right
        l.y             = mix(v.z, v.w, l.z);                //top left right
        return mix(l.x, l.y, l.w);                    //top to bottom
}
 

//fractal brownian motion, aka perlin noise - when using values of .5 and 2. it's also known as "pink noise"
float fractal_brownian_motion(vec2 uv)
{
    float amplitude = .5;                        //amplitude is how much to add per step
    float frequency = 2.;                        //frequency is how much to change scale at each step
    
    float result    = 0.;                        //iteratively stack layers of value noise to create perlin noise
    for(int i = 0; i < 8; i++)
    {
        result         += noise(uv*frequency)*amplitude;    //add value noise, using the frequency and amplitude to control it
            amplitude     *= .5;                    //at each step, half the amount you add
            frequency     *= 2.;                    //and double the spatial frequency 
       }
    
        return result;
}

#//Scene Map
//this is the scene function
//it returns the distance to the nearest object from the ray position
float map(vec3 ray_position)
{
    //make some noise
    float perlin_noise    = fractal_brownian_motion(ray_position.xz);
    //perlin_noise        *= mouse.y * .5;
    //create a floor
    float floor_height    = .2;
    for(float i = 1.; i <= 8.; i+=1.){
        floor_height -= pow(perlin_noise, i*1.5)/(i+16.);
    }
    
    //if the ray plus the floor height is below 0 on the y axis, then we hit the floor
    float floor_distance    = ray_position.y + floor_height;             

    return floor_distance;
}

#//Main Program
void main( void ) 
{
    #//Format the Screen Coordinates
    //first format the screen
    vec2 screen_coordinates         = gl_FragCoord.xy;
    screen_coordinates        /= resolution;                    //divide them by the resolution so they are in the 0 - 1 range
    screen_coordinates        = screen_coordinates - .5;            //center them by subtracting .5
    screen_coordinates         *= resolution/min(resolution.x, resolution.y);    //fix the aspect ratio
    
    
    
    
    #//Create the View
    //create a 3d view direction by warping the screen coordinates away from the center
    float field_of_view        = 1.5;                        //the field of view controls the amount of warp            
    vec3 direction            = vec3(screen_coordinates, field_of_view);    //x (left and right), y (up and down), with the fov as z (forward)
    direction            = normalize(direction);                //normalize will now warp the direction based on the ratios of x y and z
    
    
    
    
    #//Trace the Ray
    //create a starting position and a ray position
    vec3 origin    = vec3(0);
    vec3 position    = 4.*vec3(sin(time*0.1),0,-cos(time*0.1100123));
    
    //and trace your ray to find the position of the closest surface
    float surface_threshold = .001;    
    for(int i = 0; i < 128; i++)
    {
        //check the map function to get the distance to the nearest surface from this position along the ray 
        float distance_to_surface = map(position);
        
        
        //if we are close enough to the surface, we're done, so break out of the loop
        if(distance_to_surface < surface_threshold) break;
        
        
        //otherwise move the position forward along the ray
        //you can move at least as far as the last distance to the surface no matter what direction your ray is heading
        position     += direction * distance_to_surface;
    }
    
    float distance_to_scene = distance(origin, position);    //now we have the distance from the origin into the scene

    
    
    
    #//Find the Normal
    //once the position of the surface is found, we can sample nearby with a small offset to figure out which way it is facing
    //this is commonly to as the normal
    vec3 normal             = vec3(0.);
    normal.x            = map(position + vec3(.01, 0., 0.)) - map(position - vec3(.01, 0., 0.));
    normal.y            = map(position + vec3(0., .01, 0.)) - map(position - vec3(0., .01, 0.));
    normal.z            = map(position + vec3(0., 0., .01)) - map(position - vec3(0., 0., .01));
    normal            = normalize(normal);
    
    
    
    
    #//Create the light
    vec3 light_position     = vec3(mouse.x, 1., mouse.y);
    vec3 light_direction    = normalize(light_position-position);
    vec3 light_color        = vec3(.87, .8, .7);
    float incident_light    = dot(normal, light_direction);
    
    
    #//Combine the Results
    float fog         = inversesqrt(distance_to_scene);
    vec3 material         = vec3(1.);
    vec3 color        = material * incident_light * light_color * fog;
    
    glFragColor = vec4(color, 1.);     
}//sphinx
