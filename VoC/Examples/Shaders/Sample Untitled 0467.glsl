#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 40.0
#define MIN_DIST 0.01
#define MAX_STEPS 256

#define PI 3.14159265358979323846264

float sdSphere( in vec3 pos, in float rad ) {
    return length(pos)-rad;    
}

vec2 map(in vec3 position) {
    float d1 = 1.; 
        vec3 pos = position;
        vec3 p = pos;

        float rep_size = 2.;
        float rep_half = floor(rep_size * .5);

        vec3 c = vec3(
        floor((p.x + rep_half)/rep_size),
            0.,
            floor((p.z + rep_half)/rep_size)
        );
    vec3 qos = vec3(
            mod(p.x+rep_half,rep_size)-rep_half,
            p.y,
            mod(p.z+rep_half,rep_size)-rep_half
        );
    
    float th = -0.2 - 0.2*(sin(c.x + time)+sin(c.y + time));
    d1 = sdSphere(qos-vec3(0.,1.+th,0.),.5);

        // ground
    
        float fh = -0.2 - 0.2*(sin(pos.x)+sin(pos.z));
        float d2 = pos.y - fh;

        return (d2 < d1) ? vec2(d2,2.) : vec2(d1,.1);
}

vec3 get_normal( in vec3 pos ) {
    vec2 e = vec2(.0001,0.);
    return normalize(
        vec3(map(pos+e.xyy).x-map(pos-e.xyy).x,
             map(pos+e.yxy).x-map(pos-e.yxy).x,
             map(pos+e.yyx).x-map(pos-e.yyx).x
             )
        );

}

vec2 ray( in vec3 ro, in vec3 rd )
{
    float m = -1.;
    float t = 0.01;
    for (int i = 0; i<MAX_STEPS;i++) {
         vec3 pos = ro + t * rd;
        vec2 h = map(pos);
        m = h.y;
        if(abs(h.x)<(0.001*t) || (t>MAX_DIST-0.001))
            break;
           t += h.x *.5;
    }
    if(t>MAX_DIST) m=-1.;
    return vec2(t,m);
}

vec3 get_material(in float m, in vec3 pos) {
    vec3 mate = vec3(.3);    
        if ( m > 3.5) { 
            mate = vec3(.004,.001,.0);
        } else if( m > 1.5) { 
            vec3 mtp = pos;
            vec2 f=fract(mtp.xz * 1.)-0.5;
            mate *= vec3(f.x*f.y>0.0?1.0:0.0);
        } else if( m > .5) {
            mate = vec3(.03);   
        } 
    return mate;
}

float get_light(vec3 p, vec3 lightpos) {
    vec3 l = normalize(vec3(lightpos - p));
    vec3 n = get_normal(p);
    float dif = clamp(dot(l, n), 0., 1.);
    
    vec2 d = ray(p + n * MIN_DIST, l);
    if (d.x < length(lightpos - p)) {
         dif *= 0.1;
    }
    return dif;
}

vec3 render(in vec3 ro, in vec3 rd) {

    float stime = time * .3;
        vec3 col = vec3(.2,.05, 1.5) - max(rd.y,0.0)*0.5;

        vec2 tm = ray(ro, rd);

        if(tm.y>0.) {
            float t = tm.x;
            float m = tm.y;
        
            vec3 pos = ro + t * rd;
            vec3 nor = get_normal(pos);
        
            vec3 mate = get_material(m, pos);

            vec3 lightPos = vec3(3. * sin(time*.1), 2., 15. + 3. * cos(time*.1));
            vec3 lightPos2 = vec3(2.5*sin(time), 1.5 + 1.25 * sin(time*.4), 5.* cos(time*.3));
        
            float sun_dif = get_light(pos,lightPos);
        float spot_dif = get_light(pos,lightPos2);
        
            float sky_dif = clamp( .5 + .5 * dot(nor,vec3(1.,1.,0.)), 0.,1.);
            float bnc_dif = clamp( .5 + .5 * dot(nor,vec3(0.,-1.,0.)), 0.,1.);
        
            vec3 lin = vec3(0.);
            lin += vec3(9.,1.,.1)* sun_dif;
        lin += vec3(.1,1.,9.)* spot_dif;
        //lin += vec3(.5,.8,.9)* sky_dif;
        
            col = mate * lin;
            col = mix( col,vec3(.2,.05, 1.5), 1.-exp(-0.0001*t*t*t));
        }
    
        return pow(col, vec3(0.4545));
}

mat3 get_camera(vec3 ro, vec3 ta, float rotation) {
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(rotation), cos(rotation),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec2 rotate(vec2 p, float t) {
      return p * cos(t) + vec2(p.y, -p.x) * sin(t);
}

void main( void ) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy )/resolution.y;

        // camera rotation
        mat3 cameraMatrix = mat3(0.);
        float fstop = -(time * .1);

        vec3 ta = vec3(0.,0.,0. );
        vec3 ro = vec3(0.,2.25,-4.);
    
        ro.xz = rotate(ro.xz, fstop);
        ta.xz = rotate(ta.xz, fstop);
    
        cameraMatrix = get_camera(ro, ta, 0. );
        vec3 rd = cameraMatrix * normalize( vec3(uv.xy, 1.5) );

      vec3 color = render(ro, rd);
    
    glFragColor = vec4( color, 1.0 );

}
