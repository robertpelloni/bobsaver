#version 420

// Necip's first shader transfer
// Origin https://www.shadertoy.com/view/MlcSDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAXDEPTH 60.
#define FOGSTART 8.
#define FOGCOLOR vec3(1,1,1)
#define FOV 120.
#define NEARPLANE 0.0001
#define UP vec3(0.0, 1.0, 0.0)

vec2 hash2( vec2 p )
{
        // procedural white noise    
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

vec4 voronoi( in vec2 x )
{
    vec2 n = floor(x);
    vec2 f = fract(x);
    vec2 o;
    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
    vec2 mg, mr;
    float oldDist;
    
    float md = 8.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        o = hash2( n + g );
        vec2 r = g + o - f;
        float d = dot(r,r);

        if( d<md )
        {
            md = d;
            mr = r;
            mg = g;
        }
    }
    
    oldDist = md;
    
    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 8.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        o = hash2( n + g );
        vec2 r = g + o - f;

        if( dot(mr-r,mr-r)>0.00001 )
        md = min( md, dot( 0.5*(mr+r), normalize(r-mr) ) );
    }

    return vec4( md, mr, oldDist );
}

// I borrowed this useful function from: http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 getPlaneIntersectPhase(vec3 ro, vec3 rd, float planeY)
{
    
    float intersect = (planeY-(ro+rd).y)/normalize(rd).y;
    if( intersect > 0.0)
    {        
        float twistSpeed = 2.0;
        float twistScale = 1.25;
        
        vec3 p = ro+rd+normalize(rd)*intersect;
        vec4 c = voronoi( p.xz );
         
        float camDist = max(-0.35+max(p.z-ro.z, 0.0)*0.6, 0.0);
        float edgePhase = abs(p.x+(sin(twistSpeed*p.z*0.35)*1.0+sin(twistSpeed*p.z*0.5156)*0.35+sin(twistSpeed*p.z*1.241)*0.15)*twistScale);

        edgePhase *= 0.05;        
        edgePhase -= -0.925 + pow(0.065*camDist, 1.4);        
        edgePhase = mix(edgePhase, 1.0, ( 1.0-clamp(0.25*camDist, 0.0, 1.0)));        
        edgePhase = clamp(edgePhase, 0.0, 1.0);             
        edgePhase = 1.0- pow(edgePhase,2.0);
        
  //    p.xz += c.yz;
  //    camDist = max(p.z-camPosition.z +1.0, 0.0)*1.4;
  //    float cellPhase = abs(p.x+(sin(twistSpeed*p.z*0.35)*1.0+sin(twistSpeed*p.z*0.5156)*0.35+sin(twistSpeed*p.z*1.241)*0.15)*twistScale);
  //    cellPhase -= 0.5;
  //    cellPhase /= max(pow(camDist, 1.6), 1.0);        
  //    cellPhase = pow(clamp(1.0-cellPhase, 0.0, 1.0), 16.0);
  //    cellPhase *= min(0.05*camDist, 1.0);
  //    cellPhase = pow(cellPhase, 2.0);
        
        return vec3(edgePhase, c.x, intersect);      
     }
    return vec3(0.0, 0.0, 1.0/0.0);  
}

void main( void ) {
       
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 uv = surfacePos;
    
    float camDist = 1.0/tan(radians(FOV*0.5));
    
    vec2 mouse = vec2(0.0);    
//    // if( mouse.z>0.0 )
        // mouse = 2.0*mouse.xy/resolution.y-vec2(resolution.x/resolution.y,1);
    vec3 camForward = vec3(0, 0, 1);
    camForward = mat3(rotationMatrix(UP, mouse.x*-radians(90.0))) * camForward;
    vec3 camRight = cross(UP, camForward);
    camRight = mat3(rotationMatrix(camForward, radians(8.0))) * camRight;
    camForward = mat3(rotationMatrix(camRight, mouse.y*radians(90.0) + radians(-40.0))) * camForward;
    vec3 camUp = cross(camForward, camRight);
    vec3 vectorToPixel = vec3(uv.xy,camDist)*NEARPLANE;
       vectorToPixel = (uv.x*camRight + uv.y*camUp + camDist*camForward)*NEARPLANE;
    vec3 camPosition = vec3(2.0,3.0,0) + vec3(0,0,-3.5*time);// + vec3((mouse*resolution.xy.xy/resolution.xy-vec2(0.5,0.5))*1.0,0.0);
    
 //   float rumbleSpeed = 100.0;
 //   float rumbleAmount = 0.025*(sin(rumbleSpeed*time*0.35)*1.0+sin(rumbleSpeed*time*0.37)*0.35+sin(rumbleSpeed*time*1.241)*0.15);
 //   camPosition += vec3(0,rumbleAmount,0);
    
    vec4 pixel = vec4(0,0,0,1.0/0.0);
    
    vec3 phase = getPlaneIntersectPhase(camPosition, vectorToPixel, -1.0);
    pixel.rgb = vec3(phase.y);
    pixel.rgb = mix( vec3(1.0,0.1,0.0), vec3(0.6,0.05,0.0), smoothstep( phase.x-0.025, phase.x, phase.y ) );  
    
    phase = getPlaneIntersectPhase(camPosition, vectorToPixel, -0.9);
    pixel.rgb = mix( pixel.rgb, vec3(1.0), smoothstep(phase.x-0.025, phase.x, phase.y) );
    
    //pixel.rgb = vec3(phase.x);
    
    pixel.w = phase.z; 
    
    
    float fogStrength = clamp(pow(max(pixel.w-FOGSTART,0.0)/(MAXDEPTH-FOGSTART), 0.85), 0.0, 1.0);
    glFragColor = vec4(pixel.rgb*(1.0-fogStrength) + FOGCOLOR*fogStrength, 1.0);
}
