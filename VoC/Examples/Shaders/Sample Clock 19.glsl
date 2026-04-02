#version 420

// original shadertoy.com/view/3tKGRD

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = ( 2.*gl_FragCoord.xy - resolution.xy ) /resolution.y;

    vec2 p = vec2(atan(uv.x,uv.y)/6.283185+.5, length(uv));
    
    float b = .5/resolution.y;    //blur
    float r = .85;    //size
    
    // year
    float ty = date.y/12. + date.z/30./12. + date.w/86400./30./12.;
    float dy = p.x-ty;
    float sy = smoothstep(1./p.y*b, -1./p.y*b, dy);
    float cy = smoothstep(1./p.y*b*3., -1./p.y*b*3., p.y-r);
    vec3 year = vec3(max(sy*cy, .15*cy) * vec3(.2,.35,.5));
    
    // month
    float tm = date.z/30. + date.w/86400./30.;
    float dm = p.x-tm;
    float sm = smoothstep(1./p.y*b, -1./p.y*b, dm);
    float cm = smoothstep(1./p.y*b*2.6, -1./p.y*b*2.6, p.y-r+.167);
    vec3 month = vec3(max(sm*cm, .15*cm) * vec3(.43,.36,.49));

    // day
    float td = date.w/86400.;
    float dd = p.x-td;
    float sd = smoothstep(1./p.y*b, -1./p.y*b, dd);
    float cd = smoothstep(1./p.y*b*2.2, -1./p.y*b*2.2, p.y-r+.333);
    vec3 day = vec3(max(sd*cd, .15*cd) * vec3(.76,.42,.53));
    
    // hour
    float th = fract(date.w/3600.);
    float dh = p.x-th;
    float sh = smoothstep(1./p.y*b, -1./p.y*b, dh);
    float ch = smoothstep(1./p.y*b*1.8, -1./p.y*b*1.8, p.y-r+.5);
    vec3 hour = vec3(max(sh*ch, .15*ch) * vec3(.95,.43,.46));
    
    // minute
    float tmi = fract(date.w/60.);
    float dmi = p.x-tmi;
    float smi = smoothstep(1./p.y*b, -1./p.y*b, dmi);
    float cmi = smoothstep(1./p.y*b*1.2, -1./p.y*b*1.2, p.y-r+.667);
    vec3 minute = vec3(max(smi*cmi, .15*cmi) * vec3(.98,.7,.58));
    
    vec3 col = mix(mix(mix(mix(year, month, cm), day, cd), hour, ch), minute, cmi);

    glFragColor = vec4(col, 1.);
}
