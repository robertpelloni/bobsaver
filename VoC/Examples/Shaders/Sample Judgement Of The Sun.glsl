#version 420

// original https://www.shadertoy.com/view/wdGGDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Judgement of the Sun

// Many thanks to IQ
// https://www.iquilezles.org/www/articles/smin/smin.htm
// Polynomial Cubic Smooth Min (k = 0.1);
float smin(float a, float b, float k)
{
    float h = max(k-abs(a-b),0.0);
    return min(a,b)-h*h*h/(6.0*k*k);
}

// Noise
float randFloat(float n)
{
     return fract( sin( n*64.19 )*420.82 );
}
vec2 randVec2(vec2 n)
{
     return vec2(randFloat( n.x*12.95+n.y*43.72 ),randFloat( n.x*16.21+n.y*90.23 )); 
}
float worley(vec2 n, float s)
{
    float dist = 2.0;
    for( int x=-1;x<=1;x++ )
    {
        for( int y=-1;y<=1;y++ )
        {
            vec2 p = floor( n/s )+vec2(x,y);
            float d = length( randVec2( p )+vec2(x,y)-fract( n/s ) );
            if ( d < dist )
            {
                 dist = d;   
            }
        }
    }
    return dist;
}

float wave(float dist, float offset)
{
    return (0.01*sin(29.0*dist-0.9*(time+offset)))
        +(0.005*sin(72.0*dist-3.1*(time+offset)))
        +(0.003*sin(96.0*dist-4.2*(time+offset)));
}

// Clouds
void clouds(inout vec3 col, in vec2 uv)
{
    float noise = 0.8*worley(uv*64.0+vec2(-20.42*time,0.0), 128.0)+0.15*worley(uv*64.0+vec2(923.324-1.2*time,10.234), 5.0);
    float grain = randFloat(uv.x*12.95+uv.y*43.72+0.001*noise);
    noise -= grain*0.05;
    vec3 lightDir = normalize(vec3(-0.25, 0.75, 0.1));
    vec3 norm = normalize(vec3(worley(uv*256.0+vec2(90.1921,403.32), 32.0-8.0*noise)-0.5, 0.4*(worley(uv*(64.0+128.0*noise)+vec2(90.1921,3.14159), 24.0)-0.5), 0.5));
    float lightDot = dot(lightDir, norm);
    float disp = 10.0*wave(lightDot+uv.y,0.0);
    float light = clamp(0.64+lightDot, 0.0, 1.0);
    
    col = mix(vec3(0.1,0.42,0.64), col, light);
}

// Sun Arms
const vec3 ARMS_COLOR = vec3(0.4745098, 0.1098039, 0.1647059);
const vec3 ARMS_END_COLOR = vec3(0.3803922, 0.1254902, 0.1647059);
const vec3 ARMS_SPLOTCH_COLOR = vec3(0.1901961, 0.0627451, 0.0823530);
const float ARMS_INNER_RADIUS = 0.18;
const float ARMS_OUTLINE = 0.005;
const float ARMS_FEATHER = 0.0025;
const float ARMS_LENGTH = 0.48;
const float ARMS_THICKNESS = 0.042;

void arms(inout vec3 col, in vec2 uv, in vec2 id)
{
    float dist = 1.0;
    float innerDist = length(uv)-ARMS_INNER_RADIUS;
    
    //float thickness = pow((ARMS_THICKNESS*cos((2.6/ARMS_LENGTH)*dist)),0.9);
    float thickness = (1.0-pow(clamp(innerDist/(ARMS_LENGTH-ARMS_INNER_RADIUS),0.0,1.0),2.0))
        *ARMS_THICKNESS;
    
    vec3 armColor = mix(ARMS_COLOR, ARMS_END_COLOR, 
                        clamp(innerDist/(ARMS_LENGTH-ARMS_INNER_RADIUS),0.0,1.0));
    
    float armDist = 0.0;
    // Horizontal '-'
    armDist = length(uv+vec2(clamp(-uv.x,-ARMS_LENGTH,ARMS_LENGTH),
                             wave(innerDist,12.92*id.x)))-thickness+0.006;
    dist = min(dist, armDist);
    // Vertical '|'
    armDist = length(uv+vec2(wave(innerDist,91.42*id.y),
                             clamp(-uv.y,-ARMS_LENGTH,ARMS_LENGTH)))-thickness+0.006;
    dist = min(dist, armDist);
    // Diagonal '\'
    armDist = abs(uv.x+uv.y-wave(innerDist,69.32*(id.x+3.0*id.y)))
        +0.012*abs(uv.x-uv.y)-thickness*1.4;
    dist = min(dist, armDist);
    // Diagonal '/'
    armDist = abs(uv.x-uv.y+-wave(innerDist,128.13*(id.x+3.0*id.y)))
        +0.012*abs(uv.x+uv.y)-thickness*1.4;
    dist = min(dist, armDist);
    
    dist = smin(dist, innerDist, 0.05);
    
    // Background Sky Blue
    col = mix(col, vec3(0.1,0.42,0.64), dist*2.0 );
    
    float outlineMask = smoothstep(ARMS_OUTLINE+ARMS_FEATHER,ARMS_OUTLINE,dist);
    col = mix(col, vec3(0.0), outlineMask);
    float armsMask = smoothstep(ARMS_FEATHER,0.0,dist);
    float noise = 0.42*worley(uv*512.0, 32.0);
    col = mix(col, armColor*(1.0+noise), armsMask);
    
    // Splotches
    float splotchMask = pow(abs(1.0-worley(uv*(512.0), 12.0+20.0*wave(innerDist,42.13))), 4.0)*smoothstep(0.1, 0.0, innerDist)*
        smoothstep(ARMS_FEATHER+0.03,0.0,dist+0.04);
    col = mix(col, ARMS_SPLOTCH_COLOR, splotchMask);
}

// Sun Center
const vec3 CENTER_COLOR = vec3(0.6823529, 0.7058824, 0.3294118);
const float CENTER_RADIUS = 0.14;
const float CENTER_OUTLINE = 0.006;
const float CENTER_FEATHER = 0.004;

void center(inout vec3 col, in vec2 uv)
{
    float dist = length(uv)-CENTER_RADIUS;
    float outlineMask = smoothstep(CENTER_OUTLINE+CENTER_FEATHER,CENTER_OUTLINE,dist);
    col = mix(col, vec3(0.0), outlineMask);
    float centerMask = smoothstep(CENTER_FEATHER,0.0,dist);
    //col = mix(col, CENTER_COLOR, centerMask);
    //col = mix(col, CENTER_COLOR, 0.3*pow(1.0-dist,3.0));
    // Shading
    vec3 lightDir = normalize(vec3(-0.5, -0.042, 0.2));
    float light = clamp(dot(lightDir, normalize(vec3(uv/CENTER_RADIUS, 
                                                     sqrt(1.0-clamp(dot(uv, uv),0.0,1.0))))), 0.0, 1.0);
    //light = pow(light, 0.5);
    float cells1 = 1.0-pow(worley(uv*1024.0, 32.0+100.0*wave(dist,189.37)), 0.2);
    float cells2 = 1.0-pow(worley(uv*1024.0, 24.0+100.0*wave(dist,42.13)), 0.2);
    float noise = 0.8*smin(cells1, cells2, 0.5);
    float shading = 1.6*(1.0-((1.0-light)*(0.2+noise)));
    //shading = light;
    vec3 centerColor = mix(CENTER_COLOR, shading*CENTER_COLOR, 0.42);
    col = mix(col, centerColor, centerMask);
    
}

// Sun Face
const float BROW_WIDTH = 0.032;
const float BROW_THICKNESS = 0.0025;
const float BROW_L_X = -0.045;
const float BROW_L_Y = -0.074;
const float BROW_R_X = 0.06;
const float BROW_R_Y = -0.072;
const float SOCKET_WIDTH = 0.038;
const float SOCKET_THICKNESS = 0.001;
const float SOCKET_L_X = -0.053;
const float SOCKET_L_Y = -0.052;
const float SOCKET_R_X = 0.06;
const float SOCKET_R_Y = -0.052;
const float NOSE_HEIGHT = 0.035;
const float NOSE_THICKNESS = 0.0025;
const float NOSE_X = -0.015;
const float NOSE_Y = -0.029;
const float NOSTRILS_WIDTH = 0.02;
const float NOSTRILS_THICKNESS = 0.003;
const float NOSTRILS_X = 0.0;
const float NOSTRILS_Y = 0.015;
const float EYE_RADIUS = 0.005;
const float EYE_L_X = -0.052;
const float EYE_L_Y = -0.04;
const float EYE_R_X = 0.06;
const float EYE_R_Y = -0.04;
const float MOUTH_WIDTH = 0.042;
const float MOUTH_THICKNESS = 0.001;
const float MOUTH_Y = 0.05;
const float CHIN_WIDTH = 0.015;
const float CHIN_HEIGHT = 0.015;
const float CHIN_THICKNESS = 0.002;
const float CHIN_X = 0.0;
const float CHIN_Y = 0.08;
const float FACE_FEATHER = 0.0025;

void face(inout vec3 col, in vec2 uv)
{
    float dist = 1.0;
    float thickness = 0.0;
    float disp = 0.0;
    
    vec2 eyesOffset = vec2(0.008*(sin(time*0.2+0.42)+0.42*sin(time*0.31)+0.1*sin(time*1.3)),0.0);
    
    // Left Eyebrow
    thickness = BROW_THICKNESS+(0.001*sin(54.0*uv.x+2.1));
    disp = (0.006*sin(50.0*uv.x+4.9));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          BROW_L_X-BROW_WIDTH,BROW_L_X+BROW_WIDTH),
                                    BROW_L_Y-disp))-thickness);
    
    // Right Eyebrow
    thickness = BROW_THICKNESS+(0.0015*sin(54.0*uv.x-2.9));
    disp = (0.006*sin(90.0*uv.x+1.1));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          BROW_R_X-BROW_WIDTH,BROW_R_X+BROW_WIDTH),
                                    BROW_R_Y-disp))-thickness);
    // Left Eye Socket
    thickness = SOCKET_THICKNESS+(0.001*sin(54.0*uv.x-1.8));
    disp = (0.004*sin(80.0*uv.x+4.2+eyesOffset.x*42.0));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_L_X-SOCKET_WIDTH,
                                          SOCKET_L_X+SOCKET_WIDTH-0.005),
                                    SOCKET_L_Y-disp))-thickness);
    thickness = SOCKET_THICKNESS+(0.002*sin(54.0*uv.x+2.2));
    disp = (0.013*sin(120.0*uv.x+1.2));
    dist = smin(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_L_X-SOCKET_WIDTH+0.0008,
                                          SOCKET_L_X+SOCKET_WIDTH-0.072),
                                    SOCKET_L_Y+0.004-disp))-thickness,
               0.01);
    thickness = SOCKET_THICKNESS+(0.0003*sin(80.0*uv.x-3.1));
    disp = (0.003*sin(120.0*uv.x+2.2+eyesOffset.x*200.1));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_L_X-SOCKET_WIDTH+0.02,
                                          SOCKET_L_X+SOCKET_WIDTH-0.015),
                                    SOCKET_L_Y+0.022-disp))-thickness);
    
    // Right Eye Socket
    thickness = SOCKET_THICKNESS+(0.001*sin(54.0*uv.x-2.9));
    disp = (0.005*sin(100.0*uv.x+1.1+eyesOffset.x*42.0));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_R_X-SOCKET_WIDTH,
                                          SOCKET_R_X+SOCKET_WIDTH),
                                    SOCKET_R_Y-disp))-thickness);
    thickness = SOCKET_THICKNESS+(0.001*sin(54.0*uv.x-2.9));
    disp = (0.02*sin(70.0*uv.x-3.2));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_R_X-SOCKET_WIDTH-0.01,
                                          SOCKET_R_X-0.04),
                                    SOCKET_R_Y+0.022-disp))-thickness);
    thickness = SOCKET_THICKNESS+(0.0003*sin(54.0*uv.x-2.9));
    disp = (0.01*sin(70.0*uv.x-4.5+eyesOffset.x*60.0));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,
                                          SOCKET_R_X-SOCKET_WIDTH+0.015,
                                          SOCKET_R_X+SOCKET_WIDTH-0.008),
                                    SOCKET_R_Y+0.015-disp))-thickness);
    
    // Nose Bridge
    thickness = NOSE_THICKNESS+(0.0015*sin(54.0*uv.y-2.9));
    disp = (0.003*sin(120.0*uv.y-3.1));
    dist = smin(dist, length(uv+vec2(NOSE_X-disp,
                              clamp(-uv.y,NOSE_Y-NOSE_HEIGHT,NOSE_Y+NOSE_HEIGHT)))-thickness, 
                0.01);
    // Nose Nostrils
    thickness = NOSTRILS_THICKNESS+(0.002*sin(54.0*uv.x+1.0));
    disp = (0.004*sin(160.0*uv.x-2.4));
    dist = smin(dist, length(uv+vec2(clamp(-uv.x,NOSTRILS_X-NOSTRILS_WIDTH,
                                          NOSTRILS_X+NOSTRILS_WIDTH),NOSTRILS_Y-disp))-thickness,
               0.02);

    // Left Eyeball
    dist = min(dist, length(uv+vec2(EYE_L_X+eyesOffset.x,EYE_L_Y+eyesOffset.y))-EYE_RADIUS);
    // Right Eyeball
    dist = min(dist, length(uv+vec2(EYE_R_X+eyesOffset.x,EYE_R_Y+eyesOffset.y))-EYE_RADIUS);
    
    // Mouth
    thickness = MOUTH_THICKNESS+(0.0015*sin(54.0*uv.x-1.7));
    disp = (0.002*sin(120.0*uv.x-2.4));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,-MOUTH_WIDTH,MOUTH_WIDTH),
                                    MOUTH_Y-disp))-thickness);
    
    // Chin
    thickness = CHIN_THICKNESS+(0.005*sin(54.0*uv.x+0.4));
    disp = (0.003*sin(80.0*(CHIN_X+uv.x)-2.8));
    dist = min(dist, length(uv+vec2(clamp(-uv.x,CHIN_X-CHIN_WIDTH,CHIN_X+CHIN_WIDTH),
                                    CHIN_Y-disp))-thickness);
    thickness = CHIN_THICKNESS+(0.0005*sin(54.0*uv.y-2.9));
    disp = (0.006*sin(120.0*(CHIN_Y+uv.y)+3.9));
    dist = min(dist, length(uv+vec2(CHIN_X-0.022-disp,
                              clamp(-uv.y,CHIN_Y+0.02-CHIN_HEIGHT,
                                    CHIN_Y+0.01+CHIN_HEIGHT)))-thickness);
    
    col = mix(col, vec3(0.0), smoothstep(FACE_FEATHER,0.0,dist));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 cuv = (gl_FragCoord.xy-(0.5*resolution.xy))/resolution.y;
    //cuv *= 1.0+(0.5*sin(time*0.5));    // Scale in out
    vec3 col = vec3(1.0);
    vec2 id = floor(uv*2.0);
    clouds(col, cuv);
    arms(col, cuv, id);
    center(col, cuv);
    face(col, cuv);
    glFragColor = vec4(col,1.0);
}
