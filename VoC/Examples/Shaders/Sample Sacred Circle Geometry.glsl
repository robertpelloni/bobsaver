#version 420

// original https://www.shadertoy.com/view/tt23DG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

float DrawCircle(vec2 pos, float radius)
{
    // warping
    pos.x *= abs(sin(time))*.75 + .25;
    
    vec2 dist = pos-vec2(0.);
    return 1.-smoothstep(radius-(radius*0.02),
                         radius+(radius*0.02),
                         dot(dist,dist)*4.0);
}

float DrawLineCircle(vec2 pos)
{
    return DrawCircle(pos, .5) - DrawCircle(pos, .5 - .04);
}

float DrawRotatedLineCircle(vec2 p, float time, float angle)
{
    p = rotate(p, angle);
    
    float size = .35;
    float lin = 0.;
    float sinTime = sin(time);
    
    lin += DrawLineCircle(p + vec2(0., sinTime *  size));
    lin += DrawLineCircle(p + vec2(0., sinTime * -size));
    
    lin += DrawLineCircle(p + vec2(0., sinTime *  size*2.));
    lin += DrawLineCircle(p + vec2(0., sinTime * -size*2.));
    
    return lin;
}

vec3 DrawGeometry(vec2 p)
{
    // time
    float time = time;
   
    // render
    float lin = 0.;
    
    // vertical verts
    lin += DrawLineCircle(p);
    lin += DrawRotatedLineCircle(p, time, 0.);
    lin += DrawRotatedLineCircle(p, time, radians(60.));
    lin += DrawRotatedLineCircle(p, time, radians(120.));
    
    return vec3(lin);
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    p*=1.2;

    vec3 col = vec3(DrawGeometry(p));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
