#version 420

//Isotropic Automata by Chris Birke - Unbound Technologies Inc.
//
//Licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
//Based on a work at http://glslsandbox.com/e#21210.1
//Email with questions, improvements, and curiosity - cbirke@gmail.com

//Mouse bottom left to reset
//Uncomment the #define(s) below to change behaviours

//// CONTROL PARAMETERS
#define ADD_AUTOMATA
    #define RANDOM_ADD   8.
    #define POINT_ADD    0.
        #define ADD_POSITION vec2(.475,.575)

#define TRAILS .25                //weight of trails (in green)
    #define TRAIL_DECAY .125            //decay of trails

//#define CHASE_MOUSE .15            //angle to mouse influence
    #define CHASE_RANGE 1.            //range of effect

//#define AUTOMATA_COLLISION

#define MAP_COLLISION
    #define MAP_THRESHOLD mouse.x * 4. //.55        //height at which collision reflects cells
    #define MAP_RESTITUTION .05        //amount of push back for cells that cross the threshold
    #define MAP_DERIVATIVE_PATH_WEIGHT .0   //influence of path up and down the gradient
    #define MAP_TANGENT_PATH_WEIGHT mouse.y //1.      //influence of path along the gradient

//#define MEDIAN

#define WRAP

#define TAU    (8.*atan(1.))
#define PI     (4.*atan(1.))
#define ISQRT2 (sqrt(2.)/2.)
//// END CONTROL PARAMETERS

//// HEADER
uniform vec2 mouse;
uniform float time;
uniform vec2 resolution;
uniform sampler2D renderbuffer;

out vec4 glFragColor;

vec2   wrap_and_offset_uv( vec2 uv, vec2 offset);                  //wrapped uv neighbors
float  vector_to_angle(vec2 v);                                    //2d vector to 1d angle
vec2   angle_to_vector(float a);                                   //1d angle to 2d vector
float  mix_angle( float angle, float target, float rate );         //wrapped angle mix (handles crossing 0.->1.)
float  clamp_angle( float angle );                                 //clamps to min and max > 0 8 bit angle values
float  reflect_angle(float particle, float normal);                //angle reflection
float  angle_to_mouse();
float  add_at_position( float probability, float angle, vec2 position );
float  add_at_random( float probability, float angle);

//cheap hashes
float  hash(float v);
float  position_hash( vec2 uv );
float  time_position_hash( vec2 uv );

//curves
float  cross(float x);
float  convolute(float x);
vec4   convolute(vec4 x);
vec2   smooth(vec2 uv);

//screen formatting
vec2   format_to_screen( vec2 uv );
float  mask_screen_edges( float width );

//map functions
float  map(vec2 position);
vec2   derive(vec2 position, float offset);
mat2   rmat(float t);

//fractal brownian motion 
float  value_noise(in vec2 uv);
float  fbm(float a, float f, vec2 uv, const int it);

//b tree
float tree(vec2 p);
float line(vec2 p, vec2 a, vec2 b, float w);
vec2 foldY(vec2 p, float n);
//// END HEADER

//// FUNCTION MAP (TERRAIN) 
//function map (a heightfield)
float  map(vec2 position)
{
    float n = fbm(.5, 2., position, 5);
    float c = length(position-format_to_screen(mouse));
    float t = tree(-position.yx*(4.+cos(time*512.)*.0125)-vec2(.6, 0.));//+vec2(mouse.x*mouse.x*.125+.5, 0.0));
    c = step(c, n*.125);
    return max(0., n + c);
}
////

//// MAIN
//the method requires no input but the coordinates and one channel of the back buffer 
//everything else here is just one example of their use
void main() 
{   
    vec2 uv               = gl_FragCoord.xy / resolution.xy;  

    
    //an array of position offsets for the moore neighborhood
    //8 pixels around the current one, starting at the bottom and looping round to the top counter clockwise
    vec2 neighbor_offset[8]; 
    neighbor_offset[0] = vec2(  0., -1. );
    neighbor_offset[1] = vec2( -1., -1. );
    neighbor_offset[2] = vec2( -1.,  0. );
    neighbor_offset[3] = vec2( -1.,  1. );
    neighbor_offset[4] = vec2(  0.,  1. );
    neighbor_offset[5] = vec2(  1.,  1. );
    neighbor_offset[6] = vec2(  1.,  0. );
    neighbor_offset[7] = vec2(  1., -1. );
    
    vec4 prior_cell = texture2D(renderbuffer, uv);
    
    #ifdef MEDIAN
    vec4 median    = vec4(0.);
    #endif
    vec4 group    = convolute(prior_cell);
    float celerity  = pow(prior_cell.y, 1.25);

    
    //check neighbors to see if any are angled to this current position
    vec4 cell = vec4( 0. );
    float prior_error = 0.;
    bool alive = false;
    for ( int i = 0; i < 8; i++ )
    {
        float weight         = mod(float(i), 2.) == 1. ? .2 : .05;
        vec2 velocity        = neighbor_offset[i] * celerity * .25;
        velocity         *= prior_cell.w != 0. ? angle_to_vector(prior_cell.w) : vec2(1.);
        
        //create neighbor cell position
        vec2 neighbor_uv     = fract((gl_FragCoord.xy + neighbor_offset[i] + velocity)/resolution);
        
        
        //get neighbor cell
        vec4 neighbor_cell     = texture2D(renderbuffer, neighbor_uv); 
        float neighbor_angle     = neighbor_cell.w;
        
        bool is_occupied    = neighbor_angle != 0.;
        if (is_occupied)
        {   
            //see http://glslsandbox.com/e#21453.6 for some visualization of the traversal 
            vec2 sample_position    = (255.5 * gl_FragCoord.xy)/resolution;
            sample_position     *= vec2(resolution.x/resolution.y, 1.);
            
            float sample_angle     = min(neighbor_angle, fract( neighbor_angle + .5 ));    

            bool axis            = sample_angle < .125 || sample_angle > .375;

            float sample        = axis ? sample_position.y : sample_position.x;
            sample             = mod(sample, .125);

            float probability    = fract(neighbor_angle + sample);  
            
            //if the incoming angle is coming from the correct neighbor, accept the automata
            bool approaching        = floor(probability * 8.) == float( i );
            
            float error = abs(probability - float(i) * .125);
            
            //in case of collision, check to see if this would win out
            approaching            = approaching && prior_error < error;
            
            if ( approaching ) 
            {
                cell = neighbor_cell;
                alive = true;
                
                #ifdef AUTOMATA_COLLISION
                cell.x = cell.w;
                #endif
            }
            
            #ifdef AUTOMATA_COLLISION
            cell.x = clamp_angle(1. - mod(float(i), 8.) * .125 );        
            #endif
        }   
        
        #ifdef MEDIAN
        median += neighbor_cell;
        #endif
    }

    
        #ifdef ADD_AUTOMATA
    if(!alive)
    {
        float initial_angle = time_position_hash(uv * 2.);
        
                #ifdef POINT_ADD
        cell.w += add_at_position( POINT_ADD, initial_angle , ADD_POSITION);
                #endif

                #ifdef RANDOM_ADD
        cell.w += add_at_random( RANDOM_ADD,  initial_angle );
                #endif
    }
        #endif

        #ifdef CHASE_MOUSE
    float range = distance(format_to_screen(uv), format_to_screen(mouse));
    if(range < CHASE_RANGE && alive)
    {
        cell.w = mix_angle(cell.w, mix_angle(cell.w, angle_to_mouse(), CHASE_MOUSE), CHASE_MOUSE);
    }
        #endif

        #ifdef AUTOMATA_COLLISION
    if(alive)
    {
        vec2 uv_projection    = angle_to_vector(cell.w) * 2./resolution; 
        vec4 forward_cell     = texture2D(renderbuffer, uv + uv_projection);  
        bool collision        = alive && forward_cell.x != 0.;
        cell.w                = collision ? reflect_angle(cell.w, forward_cell.x) : cell.w;  
    }
        #endif 

        #ifdef MAP_COLLISION
    vec2 position           = format_to_screen(uv);
    float collision         = map(position);        
    if(alive)
    {
        vec2 projected_position         = position + angle_to_vector(cell.w) * 2./resolution;
        float projected_collision       = map(projected_position);
        
        float normal                    = vector_to_angle(derive(projected_position, .001));
        float reflection_angle          = reflect_angle(cell.w, normal);
        float escape_angle              = clamp_angle(vector_to_angle(-derive(position, MAP_RESTITUTION)));
        
        cell.w                 = projected_collision > MAP_THRESHOLD ? reflection_angle : cell.w;        
        cell.w                 = collision           > MAP_THRESHOLD ? escape_angle     : cell.w;         
        
        cell.w                 = mix_angle(cell.w,                normal, MAP_DERIVATIVE_PATH_WEIGHT);
        cell.w                        = mix_angle(cell.w, collision / MAP_THRESHOLD, MAP_TANGENT_PATH_WEIGHT);
    }

        //visualize map in blue
    cell.z = step(MAP_THRESHOLD, collision) * collision * .5 + collision *.5;
        #endif 

       #ifdef TRAILS
    cell.y                = alive ? TRAILS + prior_cell.y : prior_cell.y - TRAIL_DECAY;
    #endif

    #ifdef MEDIAN
    median.xyz /= 8.;
    cell.y = alive ? cell.y : median.y;
    #endif

        #ifndef WRAP
    cell.w *= mask_screen_edges(1.);
        #endif

        //reset on mouse in corner
    cell *= float( mouse.x + mouse.y > .02 );

    glFragColor = cell;
}//sphinx
//// END MAIN

//// ANGLES
//maps a normalized 2d vector to a 0-1 float on a radial gradient
float vector_to_angle( vec2 v )
{
    return fract( atan( v.x, v.y ) / TAU ) ;
}

vec2 angle_to_vector(float a)
{
    vec2 v = vec2(a, a) * TAU;
    return normalize(vec2(cos(v.x),sin(v.y))).yx;
}

//mix two angles without having the problem of flipping back and forth near the 0-1 boundary - can be refactored to something better
float mix_angle( float angle, float target, float rate )
{    
    angle = abs( angle - target - 1. ) < abs( angle + target ) ? angle - 1. : angle;
    angle = abs( angle - target + 1. ) < abs( angle - target ) ? angle + 1. : angle;
    return clamp_angle(fract(mix(angle, target, rate)));
}

//reflect an angle off a surface normal
float reflect_angle(float incident, float normal)
{
    return fract(abs(normal)*2.-incident-.5);
}

//returns a normalized vector from the current screen pixel to the mouse position
float angle_to_mouse()
{
    vec2 position   = format_to_screen( gl_FragCoord.xy / resolution.xy );
    vec2 mouse_pos  = format_to_screen( mouse );
    vec2 v          = mouse_pos - position;
    return vector_to_angle( v );
}
//// END ANGLES

//// CELL SPAWNING
//spawn a cell from center with a random vector
float add_at_position( float probability, float angle, vec2 position )
{
    bool spawn   = floor( gl_FragCoord.x ) == floor( resolution.x * position.x ) && floor( gl_FragCoord.y ) == floor( resolution.y * position.y );
    vec2 uv      = gl_FragCoord.xy / resolution.xy;
    spawn        = spawn && position_hash( uv * rmat( time ) ) < probability;
    return spawn ? angle : 0.;
}

//spawn a particle from a random position with a random vector 
float add_at_random( float probability, float angle )
{
    vec2 uv      = gl_FragCoord.xy / resolution.xy;
    bool spawn   = time_position_hash( uv ) + time_position_hash( uv - 1. ) < probability * .01;
    return spawn ? angle : 0.;
}
//// END CELL SPAWNING

//// FORMATTING
//centers coordinates and corrects aspect ratio for the screen
vec2 format_to_screen( vec2 p )
{
    p       = p * 2. - 1.;
    p.x     *= resolution.x / resolution.y;
    return p;
}

//clamps to +-1./256. for the 8 bit buffer
float clamp_angle(float angle)
{
    return clamp(angle, .00390625, 1.);    
}

//takes a positonal offset and creates the neighbor uv position wrapped around the space
vec2 wrap_and_offset_uv(vec2 uv, vec2 offset)
{
   offset *= mouse.x < .02 ? -1. : 1.; //reverse on mouse at left side of screen - email me if you "fix" the reversal   
   uv = fract((gl_FragCoord.xy + offset)/resolution);
   return uv;
}

//this masks out screen edges to prevent wrapping (in case you don't want that)
float mask_screen_edges( float width )
{
    return  gl_FragCoord.x < width || gl_FragCoord.x > resolution.x - width || gl_FragCoord.y < width || gl_FragCoord.y > resolution.y - width ? 0. : 1.;    
}
////END SCREEN FORMATTING

//// HASHES
//cheap hashes used for non deterministic stuff (spawning,etc)

//returns a psudo-random 0-.9999999 number
float hash( float x )
{
    const float modulus = 1234.56789;
    x = x * modulus;
    return fract( fract( x ) + x );
}

//returns a hash from uv coordinates
float position_hash( vec2 uv )
{
    return hash( uv.x + hash( uv.y + hash( -uv.y + hash( uv.x ))));
}

//returns a hash of position and time inputs
float time_position_hash( vec2 uv )
{
    return position_hash( uv * rmat(time) );
}
//// END HASHES

//// TRANSFORMATION MATRICES
//2d rotation matrix
mat2 rmat(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c,s,-s,c);
}
//// END TRANSFORMATION MATRICES

//// CURVES
float cross(float x)
{
    return abs(fract(x-.5)-.5)*2.;  
}

float convolute(float x)
{
    x = 4. * (x * (1.-x));
    return x*x;
}

vec4 convolute(vec4 x)
{
    x = 4. * (x * (1.-x));
    return x*x;
}
//// CURVES

//// MAP FUNCTIONS
//partial derivitive of map function (the surface normal)
vec2 derive(vec2 position, float offset)
{
    vec2 epsilon = vec2(offset, 0.);
    vec2 normal  = vec2(0.);
    normal.x     = map( position + epsilon.xy ) - map( position - epsilon.xy );
    normal.y     = map( position + epsilon.yx ) - map( position - epsilon.yx );
    return normalize(normal);
}

//same as above, but from the backbuffer - use this to avoid having to recalculate a field function
vec2 derive_prior(vec2 uv, float offset)
{
    vec3 epsilon = vec3(offset + 1.5, offset + 1.5, 0.) * vec3(1./resolution, 1.);
    vec2 normal  = vec2(0.);
    normal.x     = texture2D(renderbuffer, uv + epsilon.xz ).x - texture2D(renderbuffer, uv - epsilon.xz ).x;
    normal.y     = texture2D(renderbuffer, uv + epsilon.zy ).x - texture2D(renderbuffer, uv - epsilon.zy ).x;
    return normalize(normal);
}

float box(vec2 p, vec2 s)
{
    vec2 d = abs(p) - s;
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.)));
}

//value noise
float value_noise(in vec2 uv) 
{
    const float k = 257.;
    vec4 l  = vec4(floor(uv),fract(uv));
    float u = l.x + l.y * k;
    vec4 v  = vec4(u, u+1.,u+k, u+k+1.);
    v       = fract(fract(v*1.23456789)*9.18273645*v);
    l.zw    = l.zw*l.zw*(3.-2.*l.zw);
    l.x     = mix(v.x, v.y, l.z);
    l.y     = mix(v.z, v.w, l.z);
    return    mix(l.x, l.y, l.w);
}

//fractal brownian motion
float fbm(float a, float f, vec2 uv, const int it)
{
    float n = 0.;
    uv = (32.5 + uv) * rmat(.61);
    vec2 p = vec2(.3, .7);
    for(int i = 0; i < 32; i++)
    {
        if(i<it)
        {
            n += value_noise(uv*f+p)*a;
            a *= .5;
            f *= 2.;
        }
        else
        {
            break;
        }
    }
    return n;
}

vec2 foldY(vec2 p, float n)
{
    float r = length(p.xy);
    float a = atan(p.y, p.x);
    float c = PI / n;
    a = mod(a, 2.0 * c) - c; 
    p.x = r * cos(a);
    p.y = r * sin(a);
    return p;
}

float line(vec2 p, vec2 a, vec2 b, float w)
{
    if(a==b)return(0.);
    float d = distance(a, b);
    vec2  n = normalize(b - a);
    vec2  l = vec2(0.);
    l.x = max(abs(dot(p - a, n.yx * vec2(-1.0, 1.0))), 0.0);
    l.y = max(abs(dot(p - a, n) - d * 0.5) - d * 0.5, 0.0);
    return smoothstep(w, 0., l.x+l.y);
}

float tree(vec2 p)
{
    vec2 uv    = p;
    float t    = 0.;
    float l    = .9995;
    float wr   = .75;
    float lr   = .75;
    float w    = .02;
    float lw   = w/wr;

    float rot = .667 + cos(time*512.)*.0035;//mouse.x*.5+.5;
    
    float f = rot;
    float r = rot;
    
    for (int i = 0; i < 6; i++)
    {
            float b = line(p, vec2(w, 0.), p+vec2(l, 0.), w);
            t       = max(t,b);
        
        bool branch = true;//abs(p.x*.5) < abs(p.y);
            
        p     = foldY(p, f);                      
        r     = foldY(p*-r, f*.5).x;
        p.x   += l;
        l     *= lr;
        w     *= wr;
        }
    
        t = length(p)*8.;
        
    return t;
}
///// END MAP FUNCTIONS
