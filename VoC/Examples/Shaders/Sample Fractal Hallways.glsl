#version 420

// original https://www.shadertoy.com/view/43d3zr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A Fractal shader.
// Use if you want, CC0? Is that legal? Provided under CC0 license. 

// This checks for an intersection in a single axis, since
// all axis share that behavior.
//
// The behavior is nonstandard. it returns the color if there's
// a hit, but the coordinates for the next level if it's a miss.
// This is communicated with the w component, which is the distance
// but is posiitve on hit and negative on miss. 
vec4 cast_ray_1d(vec3 vector_pos, vec3 vector_dir, int mdim, int dim2, int dim3) {
    float closest_wall = 1000.0;
    vec3 norm = vec3(0);
    bool flip = false;
    
    // Flipping the direction if negative simplifies this code.
    if (vector_dir[mdim] < 0.0) {
        vector_dir *= -1.0;
        vector_pos *= -1.0;
        flip = true;
    }
    
    if (vector_pos[mdim] < 1.0) {
        float dist_n = (1.0 - vector_pos[mdim])/vector_dir[mdim];
        
        vec3 hit_pos = vector_pos + (vector_dir * dist_n);
        
        if (abs(hit_pos[dim2])<=1.0 && abs(hit_pos[dim3])<=1.0) {
            float dist = distance(hit_pos, vector_pos);
            
            if (dist < closest_wall) {
                closest_wall = dist;
                norm[mdim] = 0.5;
                
                // Check if a hit.
                if (abs(hit_pos[dim2])<=0.5 && abs(hit_pos[dim3])<=0.5) {
                    // This is a miss, so you calculate the location of 
                    // the ray for the next iteration.
                    if (flip) {
                        hit_pos *= -1.0;
                    }
                    norm = vec3(hit_pos)*2.0;
                    norm[mdim] = -1.0;
                    if (flip) {
                        norm[mdim] = 1.0;
                    }
                    return vec4(norm, -closest_wall);
                } else {
                    // Color the sides to imply some lighting.
                    if (mdim == 0) {
                        norm = vec3(0.4);
                    } else if (mdim == 1) {
                        norm = vec3(0.5);
                    } else if (mdim == 2) {
                        norm = vec3(0.6);
                    }
                    
                    // This is to add a border for looks.
                    if ((abs(hit_pos[dim2])<=0.6 && abs(hit_pos[dim3])<=0.6) ||
                        (abs(hit_pos[dim2])>=0.9 || abs(hit_pos[dim3])>=0.9) ) {
                        norm *= 0.8;
                    }
                }
            }
        }
    }
    
    return vec4(norm, closest_wall);
}

vec3 cast_ray(vec3 vector_pos, vec3 vector_dir) {
    vec4 ret = vec4(0); 
    float dist = 0.0;

    // pseudo-recursive loop for the fractal.
    for (int i=0; i<8; i++) {  
        // Check each axis.
        vec4 x_int = cast_ray_1d(vector_pos, vector_dir, 0, 1, 2); 
        vec4 y_int = cast_ray_1d(vector_pos, vector_dir, 1, 0, 2); 
        vec4 z_int = cast_ray_1d(vector_pos, vector_dir, 2, 0, 1); 

        // Find the closest hit. This works despite the potentially
        // flipped x because it only flipps if it's a miss inside
        // the wall, misses which miss the wall entirely are set
        // to distance 1000.
        if (x_int.w < y_int.w) {
            if (x_int.w < z_int.w) { 
                ret = x_int; 
            } else { 
                ret = z_int; 
            } 
        } else { 
            if (y_int.w < z_int.w) { 
                ret = y_int; 
            } else { 
                ret = z_int; 
            } 
        } 
        
        // This is for fog.
        dist += pow(abs(ret.w/2.0),2.0);

        if (ret.w < 0.0) { 
            vector_pos = ret.xyz;
        } else {
            // Apply fog if a hit.
            return ret.xyz * (1.0-(dist/6.0));
        }
        
    }

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    uv.x -= 0.5;
    uv.y -= 0.5;

    // Direction of the ray.
    vec3 in_vec_d = vec3(sin(time/5.0),0,cos(time/5.0));
    
    // Position of the ray, this has a modulo to simiulate
    // infinite movement.
    vec3 in_vec_p = vec3(0, 0, ((pow(mod(time*-0.3501, 1.0), (1.0+(in_vec_d.z/-5.0))) * 2.0)-1.0));

    float fov = 1.0;
    vec3 in_vec_d_hold = in_vec_d;

    in_vec_d.x += (in_vec_d_hold.z*(uv.x*fov));
    in_vec_d.z -= (in_vec_d_hold.x*(uv.x*fov));
    
    in_vec_d.y += uv.y*fov/1.8;

    vec3 norm = cast_ray(in_vec_p, in_vec_d);

    vec3 col = norm;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
