#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float N21(vec2 p) {
    vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
        a += dot(a, a.yzx + 79.76);
        return fract((a.x + a.y) * a.z);
}
mat2 Rot2(float a )
{
        float c = cos( a );
        float s = sin( a );
        return mat2( c, -s, s, c );
}

// uv -1 <-> 1
float snow(vec2 uv,float scale)
{
    uv+=time/scale;
    uv*=scale;
    vec2 gridIndex=floor(uv);
    vec2 posInGrid=fract(uv);
    float dist=0.0;
    vec2 pos = .5 + .35 * sin(11. * fract(sin((gridIndex + scale) * mat2(7,3,6,5)) * 5.)) - posInGrid;
    float k =length(pos);
    k=smoothstep(0., k, sin(posInGrid.x + posInGrid.y) * 0.02);
        return k;
    
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
    vec3 finalColor=vec3(0);
    
    uv.x += sin(time*1.5)*0.3;
    uv.y += cos(time*1.5)*0.3;
    uv*=0.5+sin(time)*0.2;
    
    
    float c = 0.;
    float d = length(uv);
    d = log(d);
    d = d*d;
    uv *= Rot2(d);
    c+=snow(uv,30.)*.3;
    c+=snow(uv,20.)*.5;
    c+=snow(uv,15.)*.8;
    c+=snow(uv,10.);
    c+=snow(uv,8.);
    c+=snow(uv,6.);
    c+=snow(uv,5.);
    //c+=snow(uv,3.);
    finalColor=vec3(c*1.2,c*0.75,c*0.35);
    glFragColor = vec4(finalColor*d , 1.0);
}
