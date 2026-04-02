#version 420

// original https://www.shadertoy.com/view/wt2XDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float dist(vec2 origin, vec2 target)
{
    return abs(sqrt(pow(target.x+origin.x,2.)+pow(target.y+origin.y,2.)));
}

void main(void)
{
    //pixel coord center origo
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=vec2(.5);
    
    //set aspect ratio
    float ratio=resolution.x/resolution.y;
    uv.x*=ratio;
    
    //set time
    float t = 39.2+time/3.;//*.2+time*+sin(time*8.)/4000.;

    //save o
    vec2 o=uv;
    
    //Fisheye anim
    //uv.x+=sin(t*6.)/6.;
    //uv.y+=sin(t*2.)/12.;
    
    //Fisheye
    float d=length(uv*2.);
    float z = sqrt(1.0 - d * d);
    float rad = atan(d, z) / 3.14159;
    float phi = atan(uv.y, uv.x);
    uv = vec2(rad*cos(phi)+.5,rad*sin(phi)+.5);
    uv-=vec2(.5);
    
    //save o2
    vec2 o2 = uv;
    
    //uv=o;
    
    //circles ani
    uv.x+=sin(t*6.)/6.;
    uv.y+=sin(t*2.)/12.;
    
    //circles
    float distFromCenter = dist(o,uv);
    float circles = sin(distFromCenter*-5.);

    //back to o2
    uv = o2;
    
    float r,g,b;
    
    r=g=b=circles/16.;
    
    if(uv.x > o.x + o.y*sin(t))
        r+=.1;
    
    float size = .15*sin(t/80.);
    float size2 = .003*(.6+sin(t*8.)/6.);

    
    for(float i=-500.; i<500.; i++)
    {
        vec2 position = vec2(sin(t+i*size)*.212003,cos(t-i*size)*.4003);
        
        for(float sub=1.;sub<3.;sub++)
        {
            vec2 position2=position*.6;
            position2 += vec2(sin(t+i)*.3*sub/2.,cos(t-i)*.3*sub/2.);
            position2/=vec2(1.0,1.2);
            g+=smoothstep(size2+size2, 0., distance(uv, position2))/2.;
            r+=smoothstep(size2+size2, .0, distance(uv, position2))*.6;
        }
    }

    vec3 col = vec3(r,g,b);
    glFragColor = vec4(col,1.0);
}

