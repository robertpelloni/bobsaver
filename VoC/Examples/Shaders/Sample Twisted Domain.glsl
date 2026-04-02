#version 420

// original https://www.shadertoy.com/view/4dcfW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define NEAR_CLIPPING_PLANE 0.1
#define FAR_CLIPPING_PLANE 100.0
#define MAX_MARCH_STEPS 128
#define EPSILON 0.01
#define DISTANCE_BIAS 0.7

// Change some parameters here!!
#define SPIN_SPEED 0.6
#define MOVE_SPEED 2.5

#define BEAM_WIDTH 0.4     
//Good idea Fabrice :) ^^

mat2 rotmat(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// distance functions: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opS( float d1, float d2 ) {return max(-d1,d2);}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opU( float d1, float d2 ) { return min(d1,d2);}

float sdBuilding(vec3 p) //my function that describes the "building" structure before its bent 
{
     
    vec3 b = vec3(0.0, 2.0, 0.0);
    vec3 b2 = vec3(1.1, 1.1, 1.1);

    vec3 translate = vec3(0.0, 0.0, 16.0);
    
    vec3 pos = p - translate; 
    vec3 pos2 = pos;
    vec3 pos3 = pos; 
    
    //rotate
    pos.xz *= rotmat(time * SPIN_SPEED);
    pos2.xz *= rotmat(time * SPIN_SPEED);
    pos3.xz *= rotmat(time * SPIN_SPEED);
    
    // translate down
    pos.y += time * MOVE_SPEED;
    pos2.y += time * MOVE_SPEED;
    pos3.y += time * MOVE_SPEED;
    
    pos = mod(pos, b) - 0.5 * b;
    float distance_1 = sdBox(pos, vec3(5.5, 1.0, 3.5)); // visible box
    
    pos2 = mod(pos2, b2) - 0.5 * b2;
    float distance_2 = sdBox(pos2, vec3(1.5, BEAM_WIDTH, BEAM_WIDTH)); // subtracting block
    
    pos3 = mod(pos3, b2) - 0.5 * b2;
    float distance_3 = sdBox(pos3, vec3(BEAM_WIDTH, BEAM_WIDTH, 1.5)); //subtracting block
    
    float distance_4 = opU(distance_2, distance_3); // union the two subtracting blocks
    
    float distance_5 = opS(distance_4, distance_1); // final
    
    
    return distance_5;
}

float Bend( vec3 p ) // modified version of the bend function from Iq's website
{
    float c = cos( length(p) * 0.07) ;
    float s = sin( length(p) * 0.07);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    
    return sdBuilding(q);
}

vec2 sdScene(vec3 position) // my scene
{
    
    vec3 translate = vec3(0.0, 0.0, 16.0);
    
    vec3 pos = position - translate; 
   
    float mat_id = 1.0;
    
    float distance_5 = Bend(pos);
     
    return vec2 (distance_5, mat_id);
    
}

vec2 raymarch(vec3 position, vec3 direction) // MARCH
{ 
    float depth = NEAR_CLIPPING_PLANE; 
    
    for(int i = 0; i < MAX_MARCH_STEPS; i++)
    {
         vec2 result = sdScene(position + direction * depth); 
        
        if(result.x < EPSILON) 
        {
             return vec2(depth, result.y);   
        }
        
        depth += result.x * DISTANCE_BIAS; 
                                            
        if(depth > FAR_CLIPPING_PLANE) 
            break;  
    }
    return vec2(FAR_CLIPPING_PLANE, 0.0);                                                                           
}

vec3 normal(vec3 ray_hit_position, float smoothness) //Thanks MacSlow
{  
    vec3 n;
    vec2 dn = vec2(smoothness, 0.0);
    float d = sdScene(ray_hit_position).x;
    n.x = sdScene(ray_hit_position + dn.xyy).x - d;
    n.y = sdScene(ray_hit_position + dn.yxy).x - d;
    n.z = sdScene(ray_hit_position + dn.yyx).x - d;
    return normalize(n);
}

void main(void)
{
    vec2 uv = 2.0*vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y; 
    
    vec3 camera = vec3(0.0, 0.0, 0.0); 
  
    vec3 ray_direction = normalize(vec3(uv, 2.0));
    
    vec2 result = raymarch(camera, ray_direction);
                                               
    vec3 materialColor = vec3(0.0, 0.0, 0.0);
    
    if(result.x != FAR_CLIPPING_PLANE) 
        materialColor = vec3(0.9, 0.9, 0.9);
    
  
    float fog = pow(0.4 / (0.4 + result.x), 0.3);
   
    
    vec3 intersection = camera + ray_direction * result.x;                                                        
    vec3 nrml = normal(intersection, 0.001); // get normals
    
    vec3 light_dir = normalize(vec3(0.1, 0.1, -1.0)); 
    
    float diffuse = dot(light_dir, nrml); 
    
    diffuse = max(0.3, diffuse);
    
    vec3 light_color = vec3(1.6, 1.2, 0.7) * 2.55; 
    vec3 ambient_color = vec3(0.2, 0.45, 0.5) * 1.6; 
    
    vec3 diffuseLit = materialColor * (diffuse * light_color + ambient_color); // final color for scene object
    
    if(result.x == FAR_CLIPPING_PLANE) 
    {
         glFragColor = vec4(0.0, 1.0, 1.0, 1.0);
    }
    else
    {
        glFragColor = vec4(diffuseLit, 1.0) * fog; 
    }
        
    
    
}
