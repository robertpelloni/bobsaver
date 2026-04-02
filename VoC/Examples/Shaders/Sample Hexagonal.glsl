#version 420

// original https://www.shadertoy.com/view/3lXfWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define ramp
#define freeze_stationary_points
// NOT WORKING
//#define take_shortest_direction 
#define annulus1
#define annulus2

#define pi 3.14159265
#define aspectratio resolution.y/resolution.x
#define nloops 10
#define T1 1.0
#define T2 1.0
#define T3 0.5
#define T4 0.3

float normDist(vec2 a, vec2 b)
{
    vec2 c = a-b;
    return sqrt(c.x*c.x + c.y*c.y*aspectratio*aspectratio);
}

vec3 drawLine (vec2 p1, vec2 p2, vec2 uv, float a, vec3 c)
{
    float r = 0.;
    float one_px = 1. / resolution.x; //not really one px
    
    // get dist between points
    float d = normDist(p1, p2);
    
    // get dist between current pixel and p1
    float duv = normDist(p1, uv);

    // if point is on line, according to dist, it should match current uv 
    r = 1.-floor(1.-(a*one_px)+normDist(mix(p1, p2, clamp(duv/d, 0., 1.)),  uv));
        
    return r*c;
}

vec3 drawGradientLine (vec2 p1, vec2 p2, vec2 uv, float a, vec3 c1, vec3 c2)
{
    float r = 0.;
    float one_px = 1. / resolution.x; //not really one px
    
    // get dist between points
    float d = normDist(p1, p2);
    
    // get dist between current pixel and p1
    float duv = normDist(p1, uv);

    // if point is on line, according to dist, it should match current uv 
    r = 1.-floor(1.-(a*one_px)+normDist(mix(p1, p2, clamp(duv/d, 0., 1.)),  uv));
    
    // get fraction of length along the line
    float wc = duv/d;
        
    return r*((1.-wc)*c1 + wc*c2);
}

vec3 drawCircle(vec2 p, float d, vec2 uv)
{
    return ((normDist(p, uv) <= d) ? 1. : 0.) * vec3(1.0);
}

float gauss(float x)
{
    return exp(-10000.*x*x);
}

vec3 drawGradientCircle(vec2 p, float d, vec2 uv, vec3 c1, vec3 c2)
{
    float r = normDist(p, uv);
    float nr = gauss(r);
    return ((r <= d) ? 1. : 0.) * (nr*c1 + (1.-nr)*c2);
}

vec3 drawAnnulus(vec2 p, float d1, float d2, vec2 uv, vec3 c)
{
    return (normDist(p, uv)>d1 && normDist(p,uv)<d2) ? c : vec3(0.);
}

int imod(int n, int m) {
    return n >= m ? n-m*int(floor(float(n/m))) : n;
}

float fmod(float n, float m) {
    return n >= m ? n - m*floor(n/m) : n;
}

float rand(vec2 co)
{ // pseudorandom real [0, 1]
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

int intRand(vec2 co, int m)
{ // pseudorandom integer [0, m)
    return imod(int(rand(co)*100.), m);
}

bool isNeighbour(int a, int b)
{
    return abs(a-b)==1 || abs(a-b) == 5 ? true : false;
}

bool isComplement(int a, int b)
{
    return abs(a-b)==3 ? true : false;
}

int smd(int a, int b, int m)
{ // signed modulo distance
    return b-a > m/2 ? a-b+m : b-a;
}

void main(void)
{
    vec3 lc = vec3(129., 216., 208.);
    vec3 hc = vec3(255.);
    hc /= vec3(255.);
    lc /= vec3(255.);
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float t = time;
    
    // setup a normalized time in [0.,1.]
    float nt = fmod(t, 1.);
    // optional: smooth start and end
#ifdef ramp
    nt = (cos(nt*pi)+1.)/2.;
#endif
    
    //define unit hexagon
    vec2 hex[6];
    for (int i=0; i<6; i++) {
        float n = float(i)*2.;
        hex[i] = vec2(sin(n*pi/6.), cos(n*pi/6.));
    }
    
    // scale unit hexagon to center of screen
    vec2 points[6];
    for (int i=0; i<6; i++) {
        points[i] = hex[i];
        points[i] *= vec2(aspectratio, 1.);
        points[i] *= vec2(0.5, 0.5);
        points[i] += vec2(1.0, 1.0);
        points[i] /= vec2(2.0, 2.0);
    }
    
    // animate points
    vec2 p[6];
    int q[] = int[6](0, 1, 2, 3, 4, 5);
    
    // randomize a destination point
    for (int i=0; i<6; i++) {
        // setup a consistent seed for each "loop"
        float ft = floor(t);
        // number of unique "loops" until it does a global loop
        ft = fmod(ft, float(nloops));
        // choose a number to swap with
        int a = intRand(vec2(ft, i), 6);
        // swap those two entries
        int t=q[a];
        q[a] = q[i];
        q[i] = t;
    }
    
    for (int i=0; i<6; i++) {
        // choose the endpoints
        int j = 1;
        int a = i;
        int b = q[a];
        
#ifdef freeze_stationary_points
        if (a != b) {
#endif
            // weights for a and b
            float wa = 1.-nt;
            float wb = nt;

            // setup velocities to be the tangent
            vec2 va = vec2(-hex[a].y, hex[a].x);
            vec2 vb = vec2(-hex[b].y, hex[b].x);
            // check to see if we're rotating the right way
#ifdef take_shortest_direction
            if (smd(a,b,6) > 0) {
                va *= -1.; vb *= -1.;
            }
#endif
            
            float s = 0.5;
            va *= vec2(s);
            vb *= vec2(s);
            //va = vec2(0.,0.);
            //vb = vec2(0.,0.);
            // setup 4-point stencil
            vec2 pi0 = points[a];
            vec2 pi1 = points[a]+va/3.;
            vec2 pi2 = points[b]-vb/3.;
            vec2 pi3 = points[b];
            // define bezier curve
            p[i] = wa*wa*wa*pi0 + 3.*wa*wa*wb*pi1 + 3.*wa*wb*wb*pi2 + wb*wb*wb*pi3;
#ifdef freeze_stationary_points
        } else {
            p[i] = points[a];
        }
#endif
    }
    
    vec3 lines;
    for (int i=0; i<6; i++) {
        // connect all other points
        for (int j=0; j<6; j++) {
            if (i==j) continue;
            //int a = i; int b = imod(i+1, 6);
            int a=i; int b=j;
            
            float aa = isNeighbour(a,b) ? 0.8 : 0.0; // start neighbours
            float ba = isNeighbour(a,b) ? 0.0 : 0.2; // start interior
            float ab = isNeighbour(q[a], q[b]) ? 0.8 : 0.0; // end neighbours
            float bb = isNeighbour(q[a], q[b]) ? 0.0 : 0.2; // end interior
            
            float ta = isComplement(a,b) ? T2 : T3;
            float tb = isComplement(q[a], q[b]) ? T2 : T3;
            ta += isNeighbour(a,b) ? T1 : 0.0;
            tb += isNeighbour(q[a], q[b]) ? T1 : 0.0;
            
            lines += drawLine(p[a], p[b], uv, (1.-nt)*ta + nt*tb, (1.-nt)*aa*hc+(1.-nt)*ba*lc + nt*ab*hc+nt*bb*lc);
        }
        
        // connect to complement midpoints (loop start)
        for (int j=0; j<6; j++) {
            int a=i; int b=j;
            if (!isComplement(a, b)) continue;
            
            // look for neighbours of j
            for (int k=0; k<6; k++) {
                int c=k;
                if (!isNeighbour(b, c)) continue;
                vec2 midpoint = (p[b]+p[c])/2.;
                lines += drawGradientLine(p[a], midpoint, uv, T4, (1.-nt)*vec3(0.3), vec3(0.));
            }
        }
        // connect to complement midpoints (loop end)
        for (int j=0; j<6; j++) {
            int a=i; int b=j;
            if (!isComplement(q[a], q[b])) continue;
            
            // look for neighbours of j
            for (int k=0; k<6; k++) {
                int c=k;
                if (!isNeighbour(q[b], q[c])) continue;
                vec2 midpoint = (p[b]+p[c])/2.;
                lines += drawGradientLine(p[a], midpoint, uv, T4, nt*vec3(0.3), vec3(0.));
            }
        }
    }
        
    vec3 annulus;
    for (int i=0; i<6; i++) {
#ifdef annulus1
        {
            int a = i;
            int b = q[a];

            float alpha = 0.;
            if (a == b) alpha = 1. + min(min(3.*nt, 3.-3.*nt), 1.);
            else alpha = max(1.0+(nt-1.)*3.,0.) + max(1.0+(-nt)*3.,0.);

              annulus += drawGradientCircle(p[i], 0.05, uv, alpha*vec3(0.5), vec3(0.));
        }
#endif
#ifdef annulus2
        {
            // find closest point
            float closestDist = 10000.;
            float alpha = 0.;
            if (i == q[i]) alpha = 2.;
            else {
                for (int j=0; j<6; j++)
                    closestDist = min(normDist(points[i], p[j]), closestDist);
                //alpha = max(1./(100.*closestDist+1.),0.);
                alpha = exp(-30.*closestDist);
            }

            annulus += drawAnnulus(points[i], 0.025, 0.027, uv, alpha*vec3(0.4));
        }
#endif
    }
    
    glFragColor = vec4(lines + annulus, 1.);
}
