#version 420

// original https://www.shadertoy.com/view/ttc3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec2 p,vec2 s)
{
    vec2 b = abs(p);
    vec2 a = max(b - s,vec2(0.0));
    
    //vec2 c = b / s;
    
       //float d = length(a * vec2(step(c.y,c.x),step(c.x,c.y)));
    float d = length(a);
    
    return smoothstep(0.0,0.005,d);
}

float trapezoid(vec2 p ,vec2 m,vec2 s,vec2 t1,vec2 t2,vec2 t3,vec2 t4)
{
    float g1 = box(p - m,s);
    
    vec2 t12 = t2 - t1;
    vec2 t1p = p - t1;
    
    vec2 t34 = t4 - t3;
    vec2 t3p = p - t3;
    
    float g2 = t12.x * t1p.y - t12.y * t1p.x;
    float g3 = t34.x * t3p.y - t34.y * t3p.x;
    
    return min(g1 + smoothstep(0.0,0.00015,g2) + smoothstep(0.0,0.00005,-g3),1.0);
}

float wheel(vec2 p,float s)
{
   return smoothstep(0.0,0.001,length(p) - s);
}

float curveTerrain(float p)
{
    return sin(p*6.0) + 2.5 + 0.1*sin(p*30.0)+ 0.3*cos(p*10.0)+ 0.05*sin(p*40.0+0.03);
}

float bgTerrain(vec2 p)
{
    float y = 0.33*sin(p.x*3.1415926*3.0)+ 0.025*cos(p.x*40.0) + 3.245;
    
    float y2 = 0.25*sin(p.x*3.1415926*2.150) + 4.025;
    
    return 0.75*smoothstep(-0.02,0.03,6.0 * p.y - y) + 0.65*smoothstep(-0.06,0.06,6.0 * p.y - y2); 
}

float slopedegree(float p)
{
    float dx = 1e-5;
    float dd = (curveTerrain(p + dx) - curveTerrain(p)) / dx / (2.0*3.1415926);
    
    return atan(dd);
}

float slope(vec2 p)
{
    float y = curveTerrain(p.x);
    
    return smoothstep(0.0,0.03/cos(slopedegree(p.x)),abs(6.0 * p.y - y)); 
}

float slopebg(vec2 p)
{
    float y = curveTerrain(p.x);
    
    return smoothstep(0.0,0.03,6.0 * p.y - y); 
}

float slopepos(float p)
{
    float y = curveTerrain(p);
    return 1.0 / 6.0 * y;
}

mat2 rotate(float d)
{
    float s = sin(d),
          c = cos(d);
    
       return mat2(c,-s,s,c);
}

vec3 drawScene(vec2 pos,vec2 mouse)
{
    vec3 outlineCol = vec3(0.0);
    vec3 slopeCol = vec3(0.31,0.65,0.25);
    vec3 slopebgCol = vec3(0.41,0.675,0.45)*1.36;
    vec3 carCol = vec3(1.0,0.0,0.0);
    vec3 wheelCol = vec3(0.0,0.0,0.0);
    vec3 wheelCol2 = vec3(0.6,0.4,1.0);
    vec3 col;
    
    //background
    col = slopebgCol + 0.3*bgTerrain(pos*0.65);
    
    col = mix(slopeCol,col,slopebg(pos));
    col = mix(outlineCol,col,slope(pos));
    
    //car
    vec2 carPos = vec2(mouse.x,slopepos(mouse.x));
    float degree = slopedegree(mouse.x); 
    
    vec2 posr = rotate(degree) * (pos - carPos) + carPos - vec2(0.0,0.045);
    
    vec2 windowpos = carPos+ vec2(0.03,0.007);
    vec2 poswr = rotate(-0.90) * (posr - windowpos) + windowpos ;
    
    col = mix(carCol,col,trapezoid(posr,carPos,vec2(0.06,0.03),carPos + vec2(0.02,0.03),carPos + vec2(0.04,0.005),carPos + vec2(-0.034,0.03),carPos + vec2(-0.04,0.024)));
    col = mix(wheelCol,col,wheel(posr - (carPos - vec2(0.03,0.03)),0.015));
    col = mix(wheelCol,col,wheel(posr - (carPos - vec2(-0.03,0.03)),0.015));
    
    col = mix(wheelCol2,col,wheel(posr - (carPos - vec2(0.03,0.03)),0.005));
    col = mix(wheelCol2,col,wheel(posr - (carPos - vec2(-0.03,0.03)),0.005));
    
    col = mix(vec3(0.22,0.45,1.0),col,box(poswr - windowpos,vec2(0.015,0.007))); 
    
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 mouse = mouse*resolution.xy.xy / resolution.y;
    
    vec2 pos = uv*2.0 - vec2(0.0,0.5);
    
    float t = 0.04*sin(time * 3.0 + uv.x*15.0) + 0.01 * sin(time * 1.0 + uv.x*35.0);
    
    vec3 riverCol = mix(vec3(1.0),vec3(0.0,0.7,0.8),1.0-smoothstep(t,t+0.01,pos.y));
    
    pos = pos.y < 0.0 ? vec2(pos.x,(-pos.y * 1.4 - t)) : pos;
    
    vec3 col = drawScene(pos,mouse*2.0);
    
       col *= riverCol;
    
    glFragColor = vec4(col,1.0);
}
