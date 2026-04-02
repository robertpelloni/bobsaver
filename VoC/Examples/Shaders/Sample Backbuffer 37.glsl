#version 420

uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform float time;

out vec4 glFragColor;

//uniform vec3 gravity;

#define dfac (0.6)
#define lp (9.0)
#define difq (4000.0)
#define f (0.002)

vec2 rand(vec2 u)
{
    vec2 r;
    r.x = cos(600.4*cos(2900.45*time+u.x*7.7+u.y*1.6));
    r.y = cos(800.7*cos(3208.77*time+u.x*7.86+u.y*1.6));
    
    

    return normalize(vec2(cos(u.x*0.4 ),sin(u.y*0.4)) + r*2.0 );
}

vec3 colback(vec2 v)
{
if (v.x<0.0 || v.y<0.0 || v.x > resolution.x-1.0 || v.y > resolution.y-1.0)
return vec3(0.0,0.0,0.0);

    return texture2D(backbuffer, v/resolution.xy).xyz;

}

vec3 blur(vec2 v,float d)
{
    vec3 col = colback(v+vec2(1.0,1.0));
    col += colback(v + vec2(1.0,1.0));
    col += colback(v + vec2(0.0,1.0));
    col += colback(v + vec2(-1.0,1.0));
    col += colback(v + vec2(-1.0,0.0));
    col += colback(v + vec2(-1.0,-1.0));
    col += colback(v + vec2(0.0,-1.0));
    col += colback(v + vec2(1.0,-1.0));
    col *= (1.0-d)/8.0;
    col += d*colback(v);
return col;
}

void main( void )
{
    vec3 gravity = vec3(0.0,0.0,0.0);
    
    vec2 uv = gl_FragCoord.xy;
    vec2 tc = uv/resolution.xy;
    vec3 col= vec3(0.0,0.0,0.0);
    vec2 dir[6];

        dir[0] = vec2(0.9,0.1);
        dir[1] = vec2(-0.45,0.45);
        dir[2] = vec2(0.3,-0.6);
     dir[3] = vec2(0.6,-0.3);
     dir[4] = vec2(0.1,-0.9);
     dir[5] = vec2(-0.7,-0.2);

     for(int i=0;i<6;i++)
     {
         float phi =4.0*time*cos(float(i)*5.3);
         dir[i].x=cos(phi);
         dir[i].y=sin(phi);
}
    vec2 dirpoint[6];

    for( int i=0;i<6;i++)
    {
        float k = float(i)+1.0;
        dirpoint[i].y= resolution.y*0.5 + resolution.y*0.49*cos(time*k/40.0+ sin(time)+ 54.2*k);
        dirpoint[i].x= resolution.x*0.5 + resolution.x*0.49*cos(time*(7.0-k)/84.67+cos(time)+ 54.2*k);
        }

    col.x += clamp(lp-length(dirpoint[0]-uv),0.0,lp)
           + clamp(lp-length(dirpoint[3]-uv),0.0,lp)
           + clamp(lp-length(dirpoint[4]-uv),0.0,lp);

    col.y += clamp(lp-length(dirpoint[1]-uv),0.0,lp)
           + clamp(lp-length(dirpoint[3]-uv),0.0,lp)
           + clamp(lp-length(dirpoint[5]-uv),0.0,lp);

    col.z += clamp(lp-length(dirpoint[2]-uv),0.0,lp)
        + clamp(lp-length(dirpoint[4]-uv),0.0,lp)
        + clamp(lp-length(dirpoint[5]-uv),0.0,lp);

col /= lp;

vec2 dvec=vec2(0.0);

for (int i=0;i<6;i++)
{
    dvec += 0.1*gravity.xy/9.0+2.5*dir[i]*exp(dot(-dirpoint[i]+uv,dirpoint[i]-uv)/difq);
    }
    //col = length(dvec)*vec3(1.0,1.0,1.0);
vec3 acol = blur(uv + dvec + 1.1*rand(uv),0.90);

col = 1.0*col + 1.0*acol*clamp(0.5-gravity.z/9.8,1.0,2.0);

    glFragColor = vec4(col,1.0);
}
