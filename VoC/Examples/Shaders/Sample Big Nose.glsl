#version 420

// original https://www.shadertoy.com/view/4sXSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Lanza 2014
// Default CC of Shadertoy

#define EPSILON 0.0001
#define PI 3.14159265359

// Primitives by iq
float sphere( vec3 p, float radius ) {
    return length(p) - radius;
}

float box( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// polynomial smin by iq (very powerful)
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// eye and eye lids are repeated, hence the funcs
float eyeLid( vec3 p) {
    // up lid is a sphere cut by a bounding box
    float up = max(sphere(p, 0.2), box(p - vec3(0.0, -0.1, 0.0), vec3(0.2, 0.1,0.2)));
    float down = sphere(p, 0.18);
    
    // blink every 3 secs;
    if(mod( time, 3.0) > 0.15)
        down =  max(sphere(p, 0.18), sphere( p + vec3( 0.0, -0.2, 0.1), 0.17));
    return min( up, down);
}

float eye( vec3 p) {
    return sphere( p, 0.16 );
}

// returns vec 2 : x is the distance, y the material.
vec2 scene( vec3 p )
{
    float crane = sphere(p, 0.6);
    float eyeLids = min(eyeLid(p - vec3(0.25, -0.1, 0.5)), eyeLid(p + vec3(0.25,0.1,-0.5)));
    float head = smin(crane, eyeLids, 0.07);
    head = max( head, -box( p + vec3(0.0, -0.45, -0.65), vec3(1.0, 0.2, 0.3)));
    float nose = sphere(p - vec3(0.0, 0.1, 0.6), 0.2);
    float skin = smin(head, nose, 0.09);
    float eyes = min( eye(p - vec3(0.25, -0.1, 0.5)), eye(p + vec3(0.25,0.1,-0.5)));
    
    if( min(skin, eyes) == eyes ) // hit eyes ? switch material.
        return vec2( eyes, 1.0);
    
    return vec2(skin, 0.0);
    
}

// Get normal of a point.
vec3 normal( vec3 p )
{
    vec2 n = vec2( EPSILON, 0.0 );
    return normalize( vec3 (
        scene( p + n.xyy ).x - scene( p - n.xyy ).x,
        scene( p + n.yxy ).x - scene( p - n.yxy ).x,
        scene( p + n.yyx ).x - scene( p - n.yyx ).x
        )
    );
}

// "shadowing" would be more accurate. Based on iq's...
float lighting( vec3 p, vec3 light )
{
    // march from pos to light
    vec3 ldir = normalize( light - p );
    float dist = scene(p).x;
    float t = dist;
    float maxt = length(light - p);
    
    float res = 1.0;
    for(int i = 0; i < 500; i++)
    {
        if( t >= maxt )
            break;
        
        vec3 cp = p + ldir * t;
        dist = scene(cp).x;
        
         // has to be way less than than main march's EPSILON, otherwise I get artifacts.
        if( dist < EPSILON/1000. )
            return 0.0;
        
        res = min( res, 8. * dist/t );

        t += dist;
    }
    
    return res;
}

// TODO : clean this mess.
vec4 march( vec3 cam, vec3 dir, vec2 crmouse )
{

    float t = scene(cam).x;
    vec3 light = vec3(3.0 * -sin(time), 0.2, 1.4  * cos(time));
    vec3 light2 = vec3( 0.0, 3.0, 2.0 );
    
    vec4 color = vec4( 0.2, 0.2, 0.2, 1.0 );
    
    for(int i=0; i < 50; i++)
    {
        vec3 p = cam + dir * t;
        vec2 res = scene(p);
        float dist = res.x;
        if( dist < EPSILON )
        {
            vec3 nml = normal(p);
            float shadows = lighting(p, light);
            float l = (dot(nml, normalize(light)) * shadows) /length(p - light);
            float l2 = dot(nml, normalize(light2));

            if( res.y < 0.5 ) {
                // material 1
                float red = clamp(l * 2.0, 0.0, 1.0);
                float green = clamp( l * 2.0, 1.0, 2.0) - 1.0;
                float blue = clamp( l2, 0.0, 1.0);
                color = vec4( red, green, blue, 1.0);
            }
            else
            {
                // material 2
                vec4 c = vec4(l2 + 0.2);
                vec3 eyeDir = normalize(vec3(crmouse.x - 0.5, -crmouse.y + 0.7, 3.0-cam.z*1.2)-p);
                float iris = dot( nml, eyeDir);
                vec2 centerToIris = (eyeDir - nml).xy; // awful approx... Good enough for the job.
                    
                if( iris > 0.95 )
                    c = vec4(0.0);
                else if( iris > 0.81 )
                    c = vec4(0.9 * 7.0 * (iris - 0.81),0.7,0.3,1.0);
                else if( iris > 0.78 )
                    c = vec4(0.0);
                    
                float specl = max(0.0, dot(reflect(normalize(light),nml), dir));
                float specl2 = max(0.0, dot(reflect(normalize(light2),nml), dir));
                c += 5.0 *
                    pow(specl, 190.0)  * shadows + pow(specl2, 190.0);
                c.rg *= 0.6 + 0.4 * l; 
                color = c;
            }
            
            return color;
        } 
        // Very simple edge detection.
        else if(dist > EPSILON && dist < 0.01 ) 
        {
            color = vec4(0.0);
        }
        
        t += dist;
        
    }
    return color;
}

void main(void)
{
    
    // face the camera until mouse moved. 
    // Better for preview thumbnail. Marketing's everywhere.
    vec2 crmouse = vec2(0.5, 0.67);
    if( time > 0.0 && (mouse*resolution.xy.x != 0.0 || mouse*resolution.xy.y != 0.0))
        crmouse = mouse*resolution.xy.xy/resolution.xy;
    
    // Move the cam around the scene, with a nice ellipse, to get a bigger nose when we apporach it.
    vec3 cam = vec3( 3.0 * cos(PI/3.0*((crmouse.x)+1.0) ), 0.0, 1.5 * sin(PI/3.0*((crmouse)+1.0)));
    vec3 camTarget = vec3(0.0);
    
    vec2 targetFragment = vec2(             
       gl_FragCoord.xy.x*2.0/resolution.x - 1.0,
       (gl_FragCoord.xy.y*2.0/resolution.y - 1.0) * resolution.y / resolution.x
    );
    
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross( camTarget - cam, up));
    
    // Spent some time before realizing why this is needed ^^ (and why I got silly deformation). 
    // At this point, up is world related, not cam related.
    up = normalize(cross(camTarget - cam, right));
    vec3 dir = normalize(camTarget - cam + targetFragment.x * right + targetFragment.y * up);
    
    glFragColor =  march( cam, dir, crmouse );

}
