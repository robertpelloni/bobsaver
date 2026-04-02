#version 420

// original https://www.shadertoy.com/view/WdyfDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// set to 0 or 1
#define SIMPLE 0

#define R resolution.xy
#define pi 3.14159
float ln2 = log(2.);
vec3 c0 = vec3(0,2,5)/255.;
vec3 c1 = vec3(8,45,58)/255.;
vec3 c2 = vec3(38,116,145)/255.;
vec3 c3 = vec3(167,184,181)/260.;
vec3 c4 = vec3(38,116,145)/255.;

vec3 cmap(float t) {
    vec3 col = vec3(0);
    col = mix( c0,  c1, smoothstep(0. , .2, t));
    col = mix( col, c2, smoothstep(.2, .4 , t));
    col = mix( col, c3, smoothstep(.4 , .6, t));
    col = mix( col, c4, smoothstep(.6,  .8, t));
    col = mix( col, c0, smoothstep(.8, 1.,  t));
    return col;
}

float julia(vec2 z, vec2 c, float n) {
    float i = 0.;
    for(i=0.; i < n; i++) {
        z = abs(z);
        z = mat2(z, -z.y, z.x) * z + c;
        if( dot(z,z) > 4. ) break;
    }
    return (i - log(log(dot(z,z))/ln2)/ln2) / n;
}

vec3 ripple(float t) {
    float a = 0.4;
    float b = 0.92;
    vec3 black = vec3(0);
    vec3 white = vec3(1);
    vec3 col = mix(black, white, t/a);
    col = black * smoothstep(0.0, a, t) + white * smoothstep(a, b, t) + black - smoothstep(b, 1.0, t);
    return 1.-col;    
}

void main(void)
{
    vec2 uv = 1.1*(2.*gl_FragCoord.xy-R)/R.y;
    float a = 0.2;
    float b = 0.05;
    float t = time/4.;
    float t1 = a*(cos(t)*.5+.5)-a/2.;
    float t2 = b*(cos(2.23*t)*.5 +.5)-b/2.;
    float t3 = b*(cos(5.78*t)*.5 +.5)-b/2.;
    float t4 = b*(cos(7.66*t)*.5 +.5)-b/2.;
    float t5 = b*(cos(-3.14*t)*.5 +.5)-b/2.;
    
    // https://en.wikipedia.org/wiki/Coordinate_systems_for_the_hyperbolic_plane
    vec2 uv2 = uv*uv;
    vec2 uvh = vec2(uv.x / (1.0+sqrt(1.0-uv2.x-uv2.y)), 
                    uv.y / (1.0+sqrt(1.0-uv2.x-uv2.y)));
    uvh *= mat2(cos(3.0*t1+t2), sin(2.0*t1+t3), 
                sin(3.0*t1+t4), cos(5.0*t1+t5));
    
    // Rendering of two Julia Burning Ship fractals.
    vec3 col = vec3(0);
    float f1 = julia(uvh, vec2(-0.185, 0.192), 100.+30.*t2*1.0/b+b/2.);
    float f2 = julia(2.2*uvh, vec2(-0.144, 0.228), 70.+20.*t3*1.0/b+b/2.);
    float f3 = julia(7.4*uvh, vec2(-0.185, 0.192), 60.);
    float sn = f1 + f2 + f3;
    col = cmap(fract(2.*(clamp(sn, .0, 1.) + t/4.)))
        #if !SIMPLE
        * (0.2 +     ripple(fract(15.*sn))) 
        * (0.2 + 0.8*ripple(fract(20.*sn + 0.5)))
        * (0.4 + 0.6*ripple(fract(35.*sn)))
        #endif
        ;
   
    // https://stackoverflow.com/questions/9604132/how-to-project-a-point-on-to-a-sphere
    vec3 p = vec3(uv, 0.5);
    vec3 n = p / length(p);
    vec3 light = vec3(3.75,3.75,8.1);
    vec3 v = vec3(0.,0,0.5);

    // shade
    vec3 l = normalize(p - light);
    vec3 h = normalize(v + l);
    vec3 m_spec = vec3(0.6);
    vec3 s_spec = vec3(232, 249, 255)/255.;
    float m_gsl = 1.8;
    vec3 c_spec = (m_spec * s_spec) * pow(max(-dot(n, h), 0.), m_gsl);
    vec3 m_diff = col;
    vec3 s_diff = vec3(1.0);
    vec3 c_diff = (s_diff * m_diff) * max(-dot(n, l), 0.);
    vec3 g_amb = m_diff;   
    col = c_spec + c_diff + g_amb;  
    
    
    // cut
    col *= clamp(smoothstep(0.99, 0.97, length(uv)), 0., 1.);
    
    // shadow on edges
    col *= smoothstep(1.0, 0.0, length(uv) - 0.42);
    
    glFragColor = vec4(col,1.0);
}
