#version 420

// original https://www.shadertoy.com/view/NsVczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/********************************************************************************************************************

                Cayley graph of the symmetric group S5
                
The Cayley graph of a group G with generators S, is a graph where the vertices are the elements of the group,
and the edges are of the form g-gs where g in G and h in S.
In the group S5 of all permutations of 5 elements, with the generators (1,2) (2,3) (3,4) and (4,5), there are
5!=120 elements and 120*4/2=240 edges, which is not a simple job to view in 3D. Fortunately for us, we have the 
following trick.

The group S5 acts on R5 by simply permuting the coordinates. If v in R5 has all distinct coordinates, then its
orbit has exactly |S5|=120 elements which we can identify with the group S5, and so generate the Cayley graph.
The problem is that we need 5 dimensions for that ...
To avoid this headache we use the interesting fact that the constant vectors (x,x,x,x,x) are invariant under 
the group action. This means that all the interesting part is happening on the perpendicular space, namely
all the (x,y,z,w,q) where x+y+z+w+q=0, which is 4-dimensional.
More over, permuting the coordinates doesn't change the length of a vector, so if |v|=1, then all the elements 
in its orbit have length 1, so we actually live in the unit sphere in R4, which has dimension 3.
Finally, use the streographic projection to map the 3-dimensional sphere into the standard 3-dimensional space
to get a nice presentation of this Cayley group.

********************************************************************************************************************/

// comment this SINGLE definition for an animation of graphs inside graphs
#define SINGLE              

#define PI 3.141592653589793238
#define T time
// map the segment [fromA, fromB] to [toA, toB] as a smooth step (function is constant outside the segment).
#define SM(t, fromA, fromB, toA, toB) mix(toA, toB, smoothstep(fromA,fromB,t))

const float EPSILON = 0.0005;     // for normal calculation
const float RR = 100.;            // ratio between the graphs

const vec4 e4 = vec4(0,0,0,1);
const vec4 ee = vec4(1);

// ------------------------ Some mathematics of the symmetric group ------------------------

// When considering vector in R5 where the sum of their coordinates is zero, I will use an vec4 object v,
// under the assumption that the final 5th entry is -<v,(1,1,1,1)> = -dot(v,ee).
// But because we want to work with the standard R4 space, here is an isometry between these two spaces.

// The map v -> (augM*v, -sum(augM*v)) is an isometry from R4 to vectors in R5 with zero sum.
const vec4 mm = vec4(1./sqrt(2.), 1./sqrt(6.), 1./sqrt(12.), 1./sqrt(20.));
const mat4 augM = mat4(
     0,     0,          0, -mm.x, //mm.x,
     0,     0,   -2.*mm.y,  mm.y, //mm.y,
     0,    -3.*mm.z, mm.z,  mm.z, //mm.z,
     -4.*mm.w, mm.w, mm.w,  mm.w  //mm.w
);

const mat4 augMinv = inverse(augM);

/**
 * The streographic projection.
 * Given a 4d vector v such that |v|=1 and v!=(0,0,0,1), the line from (0,0,0,1) through v intersect the space (x,y,z,0) 
 * at exactly one point. 
 * More specifically, the line is (0,0,0,1)+t*[v-(0,0,0,1)], and it intersects that space exactly when t=-1/(v.w-1).
 * Return this point.
 */
vec3 projection(vec4 v){
    return mix(e4, v, -1./(v.w-1.)).xyz;
}

/**
 * This is the inverse for the projection. This time we have some u in R^3 and we look for a point v = (1-t)*e4+t*(u,0)
 * on the line connecting u with e4, such that |v|=1.
 *           1 = |v|^2 = (1-t)^2 + t^2 * |u|^2
 *    =>     0 = (1 + |u|^2)t^2 - 2t = [(1+|u|^2)*t - 2] * t
 * t=0 is when we are at the point e4, so we need t = 2/(1+|u|^2)
 */
vec4 antiProjection(vec3 u){
    vec4 uu = vec4(u,0);
    return mix(e4, uu, 2./(1.+dot(u,u)));
}

/**
 * Standard distance to the line between a and b.
 */
float distLine(vec3 position, vec3 a, vec3 b){
    vec3 dir = b-a;
    position -= a;
    
    float distAlongLine = dot(position, dir)/dot(dir, dir);    
    float h = clamp(distAlongLine, 0., 1.);    
    return length(position-h*dir);
}

// When looking for the distance between a point p and the Cayley graph, instead of checking the distances from all the 
// vertices of the graph, we move the point p to the cell x<y<z<w<q and check the distance to the unique vertex there.

// switchIJ(p, b) := switches the i and j coordinate if b==1 and otherwise does nothing.
#define switch12(p, b) mix(p.yxzw, p.xyzw, b)
#define switch23(p, b) mix(p.xzyw, p.xyzw, b)
#define switch34(p, b) mix(p.xywz, p.xyzw, b)
#define switch45(p, b) mix(vec4(p.xyz,-dot(p,ee)), p.xyzw, b)

vec3 applyPermutation5(
        float xy4, float yz3, float xy3, float zw2, float yz2, float xy2, 
        float wq1, float zw1, float yz1, float xy1, vec4 v){
    v = switch12(v, xy4);
    v = switch23(v, yz3);
    v = switch12(v, xy3);
    v = switch34(v, zw2); 
    v = switch23(v, yz2);
    v = switch12(v, xy2);
    v = switch45(v, wq1);
    v = switch34(v, zw1);
    v = switch23(v, yz1);
    v = switch12(v, xy1);
    return projection(augMinv*v);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float distS5(vec3 position, vec4 center4){
    // lift the position to R5:
    
    // From R3 to the sphere in R4
    vec4 p = antiProjection(position);
    // Rotate to sum = 0. Think of the vector as xyzwq where q=-(x+y+z+w).
    p = augM*p;
    
    // Find the permutation that sorts the coordinates of p by bubble sort them
    
    // move max element to the q cooridnate
    float xy1 = step(p.x, p.y);
    p = switch12(p, xy1);
    
    float yz1 = step(p.y, p.z);
    p = switch23(p, yz1);
    
    float zw1 = step(p.z, p.w);
    p = switch34(p, zw1);
    
    float wq1 = step(p.w, -dot(p,ee));
    p = switch45(p, wq1);
        
    // move second max element to w cooridnate
    float xy2 = step(p.x, p.y);
    p = switch12(p, xy2);
    
    float yz2 = step(p.y, p.z);
    p = switch23(p, yz2);
    
    float zw2 = step(p.z, p.w);
    p = switch34(p, zw2);
    
    // move third max element to z cooridnate
    float xy3 = step(p.x, p.y);
    p = switch12(p, xy3);
    
    float yz3 = step(p.y, p.z);
    p = switch23(p, yz3);
    
    // sort first two elements
    float xy4 = step(p.x, p.y);
    p = switch12(p, xy4);
       
    
    // apply the transpositions in reverse order (e.g. inverse permutation) to the element
    // in the cell x<y<z<w<q, and its neighbors.
    vec3 v  = applyPermutation5(xy4, yz3, xy3, zw2, yz2, xy2, wq1, zw1, yz1, xy1, center4);
    vec3 v1 = applyPermutation5(xy4, yz3, xy3, zw2, yz2, xy2, wq1, zw1, yz1, xy1, center4.yxzw);
    vec3 v2 = applyPermutation5(xy4, yz3, xy3, zw2, yz2, xy2, wq1, zw1, yz1, xy1, center4.xzyw);
    vec3 v3 = applyPermutation5(xy4, yz3, xy3, zw2, yz2, xy2, wq1, zw1, yz1, xy1, center4.xywz);
    vec3 v4 = applyPermutation5(xy4, yz3, xy3, zw2, yz2, xy2, wq1, zw1, yz1, xy1, vec4(center4.xyz, -dot(center4,ee)));
            
    // vertices
    float d = distance(position, v)-0.02*length(v); 
    
    //edges
    float mid1 = length(mix(v,v1,0.5));
    d = opSmoothUnion(d, distLine(position, v, v1)-0.01*length(mid1), 0.1);
    float mid2 = length(mix(v,v2,0.5));
    d = opSmoothUnion(d, distLine(position, v, v2)-0.01*length(mid2), 0.1);
    float mid3 = length(mix(v,v3,0.5));
    d = opSmoothUnion(d, distLine(position, v, v3)-0.01*length(mid3), 0.1);
    float mid4 = length(mix(v,v4,0.5));
    d = opSmoothUnion(d, distLine(position, v, v4)-0.01*length(mid4), 0.1);
        
    return d;
    
}
const vec3 fogColor = vec3(0.0);
const float maxDist = 150.;

// ============================ Scene ============================

vec4 sdfMin(vec4 v, vec4 u){
    if (v.w < u.w) 
        return v; 
    return u;
}

vec4 distScene(vec3 position){  
    # if defined SINGLE
    
    vec4 v = vec4(-2,-1.,0.,1./*,2.*/)/sqrt(10.);
    
    float d = distS5(position, v);  
    vec3 color = SM(length(position),0.3,1.,vec3(1.,0.2,0.2),vec3(0.3,0.6,1.));
    
    return vec4(color, d);
    
    # else

    // One point on the graph, where the other points are the orbit of S5.
    // The point need to be in R5 (5th coordinate complete the first 4 to zero sum), and has norm 1. 
    vec4 v = vec4(-2,-1.+cos(T)/10.,sin(T)/4.,1.-cos(T)/10.);
    float vq = -dot(v,ee);
    v /= sqrt(dot(v,v)+vq*vq);

    // zoom in every 10 seconds
    float i = floor(T/10.);
    vec3 color = 0.33+fract(vec3(i+0.1,i+1.1,i+2.1)/3.);    
    float radius = SM(fract(T/10.),0.3,1.,1.,RR);
    position/=radius;
    
    // --- Consider doing this part by dividing the space according to the distance from the origin
    // --- and add one Cayley graph per such fat sphere.
    float outerDist = distS5(position/(RR*radius), v)*radius*RR;    
    vec4 outer = vec4(color.brg, outerDist);
    
    float midDist = distS5(position, v)*radius;    
    vec4 mid = vec4(color.rgb, midDist);
    
    float innerDist = distS5(position*RR, v)*radius/RR;  
    vec4 inner = vec4(color.gbr, innerDist);
        
    return sdfMin(sdfMin(outer, mid),inner);
    
    # endif
}

// ============================ Simple ray march ============================

vec3 calcNormal(vec3 p) {
  vec2 e = vec2(1.0, -1.0) * EPSILON; // epsilon
  return normalize(
    e.xyy * distScene(p + e.xyy).w +
    e.yyx * distScene(p + e.yyx).w +
    e.yxy * distScene(p + e.yxy).w +
    e.xxx * distScene(p + e.xxx).w);
}

vec4 rayMarch(in vec3 rayOrigin,in vec3 rayDirection)
{    
    float t = 0.01;
    //Material result;
    vec4 result;
    for( int i = 0; i<100; i++ )
    {
        vec3 position = rayOrigin + rayDirection * t;
        result = distScene( position );
        if( result.w < (0.001) || t > maxDist ) break;
        t += 0.8 * result.w;
    }

    if( t>maxDist ) t=-1.0;
    result.w = t;
    return result;
}

// ============================ Light ============================

const vec3 lightDir = normalize(vec3(1));

vec3 processLight(vec3 position, vec3 normal, vec3 direction){    
    // diffuse
    float diffuse = pow(clamp(-dot(lightDir, normal), 0., 1.), 0.5);
    
    //specular
    float specular = clamp(dot(-direction, reflect(lightDir, normal)), 0., 1.);
    
    //fresnel
    float dotDN = dot(direction, normal);
    float fresnel = pow((1.0 - dotDN*dotDN), 2.);
    
    return (3.*fresnel + 2.*diffuse + specular)*vec3(1);
}

void main(void)
{    
    // center and normalize coordinates
    vec2 coord = (gl_FragCoord.xy - resolution.xy/2.) / resolution.y;
   
    float t = T*2.*PI/10.; // full round every 10 seconds
    
    float st = sin(t);
    float ct = cos(t);
    
    vec3 origin = vec3(6.*st,0,6.*ct);
    vec3 target = vec3(0);
    
    // rotate camera around the y-axis
    vec3 forward, right, up;
    forward = normalize(-origin);
    right = normalize(cross(vec3(0,1,0), forward));
    up = cross(forward,right);
    
    vec3 rayDirection = normalize(forward + coord.x*right + coord.y*up);
        
    vec4 result = rayMarch(origin, rayDirection);
    float d = result.w;
    
    if (d>0.){
        vec3 position = origin + d * rayDirection;
        vec3 normal = calcNormal(position);
        vec3 color = result.rgb;
        
        color *= processLight(position, normal, rayDirection)/2.;
        // add for to far away objects
        color = SM(d, 5., 160., color, fogColor);
        
        glFragColor = vec4(color , 1.);
    } else
        glFragColor = vec4(fogColor, 1.);
}

