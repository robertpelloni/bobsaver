#version 420

// original https://www.shadertoy.com/view/tdt3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Julia 4D

  - Created by SEN ZHENG - 2019/09/14
  - Jsut enjoy it.
  - Respect to inigo quilez.I learned a lot from iq's blog and codes.
*/

#define MAX_RAYMARCHING_COUNT 320
#define PRECISION 0.0001
#define FAR 6.
#define mouse (mouse*resolution.xy.xy / resolution.xy)
#define time time

#define PI 3.1415926

struct Hit {
    float d;
    vec2 uv;
    vec3 col;
    float ref;
    float spe;
    float rough;
    float lightD;
    vec3 lightCol;
    float lightStrength;
};
    
vec2 rotate(vec2 v, float a) {
    return vec2(cos(a)*v.x + sin(a)*v.y, -sin(a)*v.x + cos(a)*v.y);
}

vec3 juliaCXYZ = vec3(0.088, 0.733, 0.722);
int juliaIterations = 12;

// quaternion 
vec4 qln(vec4 a) {
    float r = sqrt(a.w*a.w + a.y*a.y + a.z*a.z);
    float t = r > 0.00001 ? atan(r, a.x)/r : 0.0;
    return vec4(0.5*log(dot(a, a)),
                a.y * t,
                a.z * t,
                a.w * t);
}
vec4 qexp(vec4 a) {
    float r = sqrt(a.w*a.w + a.y*a.y + a.z*a.z);
    float et = exp(a.x);
    float s = r >= 0.00001 ? et*sin(r)/r : 0.0;
    return vec4(et*cos(r),
                a.y * s,
                a.z * s,
                a.w * s);
}
vec4 qpow(vec4 a, float n) {
    return qexp(n*qln(a));
}
vec4 qmul(vec4 b, vec4 a) {
    return vec4(a.x*b.x - a.y*b.y - a.z*b.z - a.w*b.w,
                a.y*b.x + a.x*b.y - a.w*b.z + a.z*b.w,
                a.z*b.x + a.w*b.y + a.x*b.z - a.y*b.w,
                a.w*b.x - a.z*b.y + a.y*b.z + a.x*b.w);
}

Hit julia(vec3 p) {
    float globalScale =  0.7;
    p /= globalScale;
    p.zy = rotate(p.zy, time*0.5);
    p.x *= .4;
    
    float Power = 6.0 + sin(time*0.6)*2.0;
    vec4 z = vec4(p, 0.0);
    vec4 zderiv = vec4(1.0);
    float dr = 1.0;
    float r = dot(z, z);
    vec4 offsetC = vec4(juliaCXYZ + vec3(sin(time*0.3 + PI),cos(time*0.6+PI),cos(time*0.1 + PI))*0.1, 0.0);
    int i = 0;
    for (; i < juliaIterations ; i++) {
        r = dot(z, z);
        if (r>20.0) break;
        zderiv = qmul(offsetC,zderiv) - qmul(qmul(Power*offsetC, qpow(z, Power-1.0)),zderiv);
        dr = dot(zderiv,zderiv);
        z = qmul(offsetC, (z - qpow(z, Power)));
    }
    r = sqrt(r);
    dr = sqrt(dr);
    float d = 0.5*log(r)*r/dr*globalScale;
    
    float uv = pow(float(i)/float(juliaIterations), 6.0);
    vec3 col0 = vec3(0.27, 0.3, 0.32);
    vec3 col1 = vec3(1.0, 0.4, 0.2);
    vec3 col = mix(col0, col1, uv);
    
    return Hit(d, vec2(uv), col, (1.0-uv)*0.0, 1.0-uv, 0.0, d, vec3(0), 0.0);
}

Hit map2(vec3 p) {
    Hit res = julia(p);
    return res;
}

vec3 calcuNormal(in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.001;   
    return normalize(e.yxx*map2(p + e.yxx).d + e.xxy*map2(p + e.xxy).d + 
                     e.xyx*map2(p + e.xyx).d + e.yyy*map2(p + e.yyy).d );   
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map2( ro + rd*t ).d;
        res = min( res, 5.0*h/t );
        t += clamp( h, 0.02, 0.2 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.2, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map2( aopos ).d;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec4 render(vec3 ro, vec3 rd, vec2 samplepos) {
    Hit hitdata;
    float t = 0.0;
    float told = t, mid, dn;
    float d = map2(rd*t + ro).d;
    float sgn = sign(d);

    if (sgn < 0.0) return vec4(0);
    
    vec3 col = vec3(1.0, 0.0, 0.0);
    
    vec3 bgCol = pow(vec3(max(0.0, dot(rd, -normalize(ro))))*0.5, vec3(1.8)) * vec3(1.0, 1.05, 1.15);
    //bgCol = texture( iChannel0, rd ).xyz;
    
    // light source
    vec3 lp = vec3(ro.x, 3.0, ro.z);
    
    float forwardstep = FAR / float(MAX_RAYMARCHING_COUNT);
    
    for (int i = 0 ; i < MAX_RAYMARCHING_COUNT ; i++) {
        
        vec3 sp = ro + rd*t;
        vec3 sundir = lp - sp;
        float sundist = length(sundir);
        vec3 ld = normalize(sundir);
        
        hitdata = map2(rd*t + ro);
        d = hitdata.d;
        
        if (sign(d) != sgn || d < PRECISION) {
        
            // The code below is useful for those sdf function that may return Negative Distance.
            // But in this scene, Julia(also Mandelbulb) always return Positive Distance, so I just comment them.
            
            /*if (sign(d) != sgn) {
                hitdata = map2(rd*told + ro);
                dn = sign(hitdata.d);
                vec2 iv = vec2(told, t);
                
                for (int j = 0 ; j < 8 ; j++) {
                    mid = dot(iv, vec2(.5));
                    hitdata = map2(rd*mid + ro);
                    d = hitdata.d;
                    if (abs(d) < PRECISION) break;
                    iv = mix(vec2(iv.x, mid), vec2(mid, iv.y),step(0.0, d*dn));
                }
                t = mid;
            }*/
            
            vec3 nor = normalize(calcuNormal(sp));
            float shd = calcSoftshadow( sp, ld, 0.02, FAR );
            float occ = calcAO( sp, nor );
            
            vec3 hal = normalize( lp - rd );
            float amb = clamp( 0.3+ 0.7*nor.y, 0.0, 1.0 );
            float dif = max( dot( ld, nor ), 0.0);
            float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ), 32.0)*dif;
            float bac = clamp( dot( nor, normalize(vec3(lp.x,-lp.y,lp.z))), 0.0, 1.0 );
            
            // surface color
            col = hitdata.col;
            
            vec3 lin = vec3(2.) * dif * shd;
            lin += 0.3*amb*vec3(1)*occ;
            lin += 0.3*bac*vec3(1)*occ;
            lin += hitdata.spe*spe*vec3(1.2);//*occ;
            col *= lin;
            
            // reflect
            vec3 r = reflect(rd, nor);
            //col += texture( iChannel0, r ).xyz * hitdata.ref;
            
            //col = mix(col, bgCol, smoothstep(0.5, FAR, t));

            break;
        } else if (t >= FAR || i+1 == MAX_RAYMARCHING_COUNT) {
            col = bgCol;
            break;
        }
        
        told = t;
        t += d;
        t = min(FAR, t);
    }
    col = pow(col, vec3(1.2));
    
    return vec4(col, t);
}

mat3 setCamera(vec3 ro, vec3 lookAt, vec3 cp) {
    vec3 cw = normalize(lookAt-ro);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    
    float dist = 2.2;
    vec3 ro = vec3(sin(time*0.5)*dist, 0.0, cos(time*0.5)*dist);
    vec3 lookAt = vec3(0.0);
    vec3 camup = vec3(0.0, 1.0, 0.0);
    mat3 viewMat = setCamera(ro, lookAt, camup);
    
    vec3 rd = viewMat * normalize(vec3(p, 1.));
    vec4 col = render( ro, rd, p );

    glFragColor = vec4(col.rgb, 1.0);
}
