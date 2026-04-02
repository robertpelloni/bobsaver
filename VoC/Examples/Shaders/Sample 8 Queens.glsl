#version 420

// original https://www.shadertoy.com/view/ltySzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float eps = .01, far = 33. ;    //raymarching parameters
const int iter  =120, AA = 1;

const float s1 = 0.447213595,     //sin of pieces grid
            c1 = 0.894427191,     //cos of pieces grid
            c2 = 0.796083798,    //cos of clip box
            s2 = 0.605186405,    //sin of clip box
            r5 = 2.236067977;     //root 5

const vec3 lightPos = vec3(9,8,6);
const vec3 lightCol = vec3(1.,.9,.8);

//smoothstep spline
float spline(float t){
    return t * t * (3. - 2.*t);
}

float box(vec3 p, vec3 s){
    p = abs(p) - s;
    return min(max(p.x,max(p.y,p.z)),0.0) + length(max(p,0.0));
}

//octagon fold then sphere test
//s = ring radius, sphere radius
float spheres(vec3 p, vec2 s){
    p.xz = abs(p.xz);
    vec2 fold = vec2(-.70710678,.70710678);
    p.xz -= 2. * max(dot(p.xz, fold), 0.) * fold;
    return distance(p, vec3(0.9238795* s.x,0.,0.3826834*s.x)) - s.y;
}

//cylinder with smoothstepped radius
float base(vec3 p){
  float t = spline(-p.y*.75+.33);
  vec2 s = vec2(.4*t*t +.2,.99); 
  vec2 d = abs(vec2(length(p.xz),p.y)) - s;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));    
}

//square cross-section torus, s = major, minor radius 
float sharpTorus(vec3 p, vec2 s){
    float d = length(p.xz) - s.x;
    vec2 v = vec2(d, p.y);
    return dot(abs(v),vec2(.70710678)) -s.y;
}

//from iq's primitives
float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

//put it all together to make a queen
float queen(vec3 p){
    float d = base(p);
    p.y += .5;
    d = max(d, - sharpTorus(p,vec2(.49,.05)));
    p.y += .25;
    d = max(d, - sharpTorus(p,vec2(.6,.05)));
    p.y -= 1.78;
    d = max(d, - spheres(p, vec2(.33,.12)));
    p.y -= .08;
    d = min(d, sdEllipsoid(p,vec3(.15,.25,.15)));
    return d;  
}

//mirrored repeating grid of queens clipped by bounding box
float queens(vec3 p){
    float flip = dot(p.xz, vec2(1.)) >= 0. ? 1. : -1.;
    p.xz *= flip;
    vec3 q = p;
    p.xz -= 1.;
    p.xz = mat2(c1,-s1,s1,c1)*p.xz;
    p.xz = mod(p.xz + r5, 2.*r5) - r5;  
    q.xz -= vec2 (4.2,3.6);
    q.xz = mat2(c2,s2,-s2,c2) * q.xz;

    return max(queen(p),box(q,vec3(6,1.5,3)));
}

float board(vec3 p){
    return box(p,vec3(7.99,1,7.99));
}

float ground(vec3 p){
    p.y += 2.;
    return box(p,vec3(13,.8,13));
}

float DE(vec3 p){
    vec3 q = p;
    q.y += 2.;
    return min(ground(p),min(queens(p), board(q)));
}

float march(vec3 ro, vec3 rd){
     float t = 0., d = 1e10;
    for(int i=0;i<iter;i++){
         t += .5 * (d = DE(ro+t*rd));
        if(d<=eps || t>= far) break;
    }
    return t+.5*d;
}

float shadow(vec3 ro, vec3 rd, float dist, float k){
    float t = eps, shade = 1.,  d;
    for(int i=0; i<50 && t < dist; i++){
        d = DE(ro + t*rd);
        if(d < 0.){
            shade = 0.;
            break;
        }
        shade = min (shade, smoothstep(0.,1.,d*k/t));
        t+= clamp(.6*d,.02,.2);
    }
    return shade;
}

vec3 getNorm(vec3 p){
    vec2 e = vec2(eps,0);
    return normalize(vec3(DE(p+e.xyy)-DE(p-e.xyy),DE(p+e.yxy)-DE(p-e.yxy),DE(p+e.yyx)-DE(p-e.yyx)));
}

//xyz for albedo, w controls specular / reflections
vec4 getMaterial(vec3 p){
    float bw = mod (floor(p.x*.5) + floor(p.z*.5), 2.);
    float d = DE(p);
    if(d == queens(p)) return bw > 0. ? vec4(.05,.05,.05, 3.15) : vec4 (.9,.9,.7, 3.15);
    if(d == ground(p)) return vec4(0.0);//vec4(pow(texture(iChannel1, .2*p.xz).rgb,vec3(2.2)),2.02); 
    return bw > 0. ? vec4(.7,.7,.7,120.99) : vec4 (.1,.1,.1,120.99);          
}

vec3 getReflection(vec3 ro, vec3 rd){
    float t = march(ro,rd);
    vec3 p = ro + t*rd;
    vec3 col;
    if(t<far){
        vec3 p = ro + t*rd;
        vec3 n = getNorm(p);
        vec3 r = reflect(rd, n);
        vec4 mat = getMaterial(p);
        vec3 l = lightPos - p;
        float d = length(l);
        l *= 1./d;
        float atten = 70. /( 1. + d*d);
        float diff = max(dot(n,l), 0.) * atten;
        float amb = .05 + .01 * n.y;
        float spec = pow(max(dot(r,l),0.),floor(mat.w))*(fract(mat.w)*4.*atten);
        col = lightCol * (mat.rgb*(diff+amb)+spec);  
    }
    else col = vec3(0.0);//.05*pow(texture(iChannel0,rd).rgb,vec3(2.2));
    return col;
}

vec3 light(vec3 p, vec3 v){
    vec3 n = getNorm(p);
    vec3 r = reflect(v, n);
    vec4 mat = getMaterial(p);
    vec3 l = lightPos - p;
    float d = length(l);
    l *= 1./d;
    float atten = 70. /( 1. + d*d);
    atten = min(atten, shadow(p, l, d, 30.));
    float diff = max(dot(n,l), 0.) * atten;
    float amb = .05 + .01 * n.y;
    float spec = pow(max(dot(r,l),0.),floor(mat.w))*(fract(mat.w)*4.*atten);
    vec3 col = lightCol * (mat.rgb*(diff+amb)+spec);  
    
    if(mat.w > 100.){
        col += .15*getReflection(p+(3.*eps*r), r);
    }
    return col;
}

void getCam(vec2 uv, vec3 ro, out vec3 rd){
    
    vec3 f = normalize(-ro);
    vec3 r = cross(vec3(0,1,0),f);
    vec3 u = cross(f,r);
    rd = normalize(f + uv.x*r + uv.y *u);
}

//iq's sphere density function for glowing light 
float sphDensity( vec3  ro, vec3  rd,   // ray origin, ray direction
                 vec3  sc, float sr) {  // sphere center, sphere radius)       
    vec3  rc = (ro - sc)/sr;
    
    // find intersection with sphere
    float b = dot(rd,rc);
    float c = dot(rc,rc) - 1.0;
    float h = b*b - c;

    // not intersecting
    if( h<0.0 ) return 0.0;
    
    h = sqrt( h );
    
    //return h*h*h;

    float t1 = -b - h;
    float t2 = -b + h;

    // analytical integration of an inverse squared density
    float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
    float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
    return (i2-i1)*1.25;
}

void main(void)
{    
    vec4 s = sin(vec4(time*.5,time*.5+1.57,time*.2,time*.3));
    vec3 ro = vec3((12.+2.*s.z)*s.x ,3. + s.w ,(12.+2.*s.z)*s.y);
    vec3 rd;
    vec3 col;
    float f = 1. / float(AA);
    for(int i=0;i<AA;i++){
        for(int j=0;j<AA;j++){
            vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy + f*vec2(i,j)) / resolution.y;
            getCam(uv,ro,rd);
            float t = march(ro,rd);
            col += t<far ? (light(ro+t*rd, rd)) : vec3(.05);
        }
    }
    col *= (f*f);
    if(dot(rd,normalize(lightPos-ro)) > .99) {
        
        float s = sphDensity(ro,rd,lightPos,2.5);
        col += clamp(s*s,0.,1.5) * lightCol;
    }
    col = pow(col, vec3(1./2.2));
    glFragColor = (vec4(col,1.0));
}
