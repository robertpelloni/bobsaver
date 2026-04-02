#version 420

// original https://www.shadertoy.com/view/MtG3zm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//By Sean Irby
//sean.t.irby@gmail.com

float widthRange = 0.025;
float scale = 20.0;
float alpha = 1.0;

float square(vec2 r, vec2 center, float width, float angle){
    width = width/2.0;
    
    r = vec2(cos(angle)*(r.x - center.x) - sin(angle)*(r.y-center.y) + center.x,
             sin(angle)*(r.x - center.x) + cos(angle)*(r.y-center.y) + center.y);
    
    if(r.x > (center.x - width) && r.x < (center.x + width) && r.y > (center.y - width) && r.y < (center.y + width))
    {
        return alpha;
    }
    
    return 0.0;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float round(float x)
{
    return floor(x + 0.5);
}

float grid(vec2 r, float scale)
{
    vec2 rp;
    
    float angle = 0.0;
    float mask = 0.0;
    float widthFreq;
    float widthPhase;
    float boxWidth;
    float scaleMult;
    
    //iterate the 3x3 grid surrounding r
    //see if im in any of the boxes
    for(float i = -1.0; i < 2.0; ++i)
    {
        for(float j = -1.0; j < 2.0; ++j)
        {
            rp = vec2(round(r.x*scale + i), round(r.y*scale + j));
            
            //Uncomment this for angle modulation
            //angle = 3.0*(rand(vec2(rp.x + 0.3, rp.y)) - 1.0)*time/3.0;
            widthPhase = rand(vec2(rp.x + 0.1, rp.y));
            widthFreq = 5.0*rand(vec2(rp.x + 0.2, rp.y));
            scaleMult = 1.0*rand(vec2(rp.x, rp.y));
            boxWidth = scaleMult*scale*(widthRange + widthRange*sin(time*widthFreq + widthPhase));
            
            mask += square(vec2(r.x*scale, r.y*scale), rp, boxWidth, angle);
        }
    }
    
    
    return mask;
}

void main(void)
{
    //normalize x and y to [-1, 1]
    vec2 r = 2.0*vec2(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;

    glFragColor = vec4(vec3(1.0, 1.0, 1.0)*grid(r, scale), 1.0);
}
