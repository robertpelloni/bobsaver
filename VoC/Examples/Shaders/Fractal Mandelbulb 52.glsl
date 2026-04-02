#version 420

// original https://www.shadertoy.com/view/WtdfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Let's declare our Ray objects with an origin and a direction.
struct Ray { 
    vec3 origin;
    vec3 dir;
};
    
//boilerplate function for rotating points - I wrote one myself but it was much less impressive and concise than this so I replaced it.
//still don't really get matrices but this takes a point and axes and does some magic. will come back later to figure this whole
//matrix multiplication thing out.
vec3 rotate( vec3 pos, float x, float y, float z )
{
    mat3 rotX = mat3( 1.0, 0.0, 0.0, 0.0, cos( x ), -sin( x ), 0.0, sin( x ), cos( x ) );
    mat3 rotY = mat3( cos( y ), 0.0, sin( y ), 0.0, 1.0, 0.0, -sin(y), 0.0, cos(y) );
    mat3 rotZ = mat3( cos( z ), -sin( z ), 0.0, sin( z ), cos( z ), 0.0, 0.0, 0.0, 1.0 );

    return rotX * rotY * rotZ * pos;
}

//THIS is the actual mandelbulb formula - again still some reading to do but the point of this function, like any SDF, is to take
//in a test point and figure out the distance to the fractal edge itself, positive or negative. 
float hit( vec3 r )
{
    r = rotate( r, sin(time / 4.0), cos(time / 4.0), 0.0 );
    vec3 zn = vec3( r.xyz );
    float rad = 0.0;
    float hit = 0.0;
    float p = 8.0;
    float d = 1.0;
    for( int i = 0; i < 10; i++ )
    {
        
            rad = length( zn );

            if( rad > 2.0 )
            {    
                hit = 0.5 * log(rad) * rad / d;
            }else{

            float th = atan( length( zn.xy ), zn.z );
            float phi = atan( zn.y, zn.x );        
            float rado = pow(rad,8.0);
            d = pow(rad, 7.0) * 7.0 * d + 1.0;
            

            float sint = sin( th * p );
            zn.x = rado * sint * cos( phi * p );
            zn.y = rado * sint * sin( phi * p );
            zn.z = rado * cos( th * p ) ;
            zn += r;
            }
            
    }
    
    return hit;
}

//Bridge between the fragment shader and the mandelbulb formula above: converts Rays to 3d vector points to test with. 
float distToScene(in Ray r) {
    return hit(r.origin);
}

vec3 lerp(vec3 colorone, vec3 colortwo, float value)
{
    return (colorone + value*(colortwo-colorone));
}

//The actual fragment shader: this runs once for every pixel in the image
void main(void) {
    //Normalize the pixel coords coming in and account for aspect ratio etc etc. 
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.y *= resolution.y / resolution.x;
    //The important part: Make a ray at 0,0 and slightly in front of the origin, and with a direction based on the pixel it's coming from
    Ray ray = Ray(vec3(0.0, 0.0, -2.0 + (sin(time) * 0.5)), normalize(vec3(uv, 1.)));
    vec3 col = vec3(0.);
    //now march it!
    for (int i=0; i<100; i++) {
        //run this part 100 times: calculate the distance between the current ray position and the fractal
        float dist = distToScene(ray); 
        if (dist < 0.001) {
            //if we're less than 0.001 away from it then assume we've hit it, and set the color accordingly
            col = vec3(1.0 / (float(i)/8.0));
            break;
        }
        //otherwise march forward the maximum amount and try again. if you never hit the fractal, the color will remain black.
        ray.origin += ray.dir * dist;
    }
    //output the colour we got multiplied by a tint: in this case red with a smidge of green and blue. Try messing with the vec3 arguments below to produce other colours.
    //glFragColor.rgb = col * vec3(0.6, 0.15, 0.05);
    vec3 black = vec3(0.0, 0.0, 0.0);
    vec3 red = vec3(0.6, 0.15, 0.05);
    vec3 orange = vec3(1.0, 0.62, 0.13) * 0.15;
    vec3 main = lerp(black, red, col.r);
    vec3 edge = lerp(black, orange, pow(col.r, 3.5));
    vec3 lerpcolor = main + edge;
    
    glFragColor.rgb = lerpcolor;
}
