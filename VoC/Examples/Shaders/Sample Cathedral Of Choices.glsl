#version 420

// original https://www.shadertoy.com/view/NtKSW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 255;
const int MAX_ROOM_DEPTH = 12;
const float MIN_DIST = 0.0;
const float MAX_DIST = 40.0;
const float EPSILON = 0.0001;
const float PI = 3.1415926535897932384626433832795;
const float DOOR_WIDTH = 1.5;
const float DOOR_HEIGHT = 0.8 + DOOR_WIDTH;
const float STEP_HEIGHT = 0.2;
const float ROOM_TIME = 6.0;

struct SceneD
{
    float d;
    int rd;
    int rn;
    float ra;
    vec3 rp;
};

float time2()
{
    return mod(time, ROOM_TIME) / ROOM_TIME;
}

int timeDepth()
{
    return int(time / ROOM_TIME);
}

int roomDoorsByDepth(int depth)
{
    return 5 + int(3.0 + 3.0 * cos(float(depth) * 1237.1));
}

int nextDoorByDepth(int depth, int doors)
{
    return 1 + int(float(doors - 1) * 0.5 * (1.0 + sin(float(depth + doors) * 1343.5)));
}

float roomRadius(int n)
{
    return 1.4 * DOOR_WIDTH * float(n) * 0.5 / PI;
}

float doorAngle(int n)
{
    return 2.0 * PI / float(n);
}

float centerDist(int n1, int n2)
{
    return roomRadius(n1) * cos(doorAngle(n1) / 2.0) + roomRadius(n2) * cos(doorAngle(n2) / 2.0);
}

float nextDoorAngle()
{
    int doors = roomDoorsByDepth(timeDepth());
    return doorAngle(doors) * float(nextDoorByDepth(timeDepth(), doors));
}

SceneD roomSDF(vec2 ey_, vec3 p_, float ra_, int rd_, int en_, int n_)
{
    vec2 ey = ey_;
    int rdepth = rd_;
    vec3 p = p_;
    float ra = ra_;
    int en = en_;
    int n = n_;
    
    for (int r = 0; true; ++r)
    {
        float lenpxz = length(p.xz);
        float pa = atan(p.z, p.x);
        float ea = atan(-1.0, 0.0);
        float da = doorAngle(n);
        float rr = roomRadius(n);
        float a = mod(2.0 * PI + pa - ea + da * 0.5, da) - da * 0.5;

        if (r < MAX_ROOM_DEPTH && length(p.xz) >= rr)
        {
            float cta = dot(ey,ey) + dot(p.xz,p.xz) - 2.0 * dot(ey,p.xz);
            float ctb = 2.0 * (dot(ey,p.xz) - dot(ey,ey));
            float ctc = dot(ey,ey) - rr * rr;
            if (ctb * ctb >= 4.0 * cta * ctc)
            {
                float ct = (-ctb + sqrt(ctb * ctb - 4.0 * cta * ctc)) / (2.0 * cta);
                vec2 ctv = vec2(ey * (1.0-ct) + p.xz * ct);

                int dn = (int((2.0 * PI + atan(ctv.y, ctv.x) - ea + da * 0.5) / da)) % n;
                a = mod(4.0 * PI + pa - ea - float(dn) * da, 2.0 * PI);

                vec2 urcv = normalize(vec2(p.x * cos(a) + p.z * sin(a), p.z * cos(a) - p.x * sin(a)));
                int ndd = nextDoorByDepth(rdepth, n);
                rdepth += 1;
                int nextn = dn == ndd ? roomDoorsByDepth(rdepth) : 5 + ((23 * dn) % 7);
                vec2 rcv = (centerDist(n, nextn) + 0.0) * urcv;

                float vra = mod(PI + float(dn) * da, 2.0 * PI);
                p = vec3(p.x - rcv.x, (dn == 0) ? p.y + STEP_HEIGHT : p.y - STEP_HEIGHT, p.z - rcv.y);
                p = vec3(p.x * cos(vra) + p.z * sin(vra), p.y, -p.x * sin(vra) + p.z * cos(vra));
                ey = ey - rcv;
                ey = vec2(ey.x * cos(vra) + ey.y * sin(vra), -ey.x * sin(vra) + ey.y * cos(vra));
                ra += vra;
                en = n;
                n = nextn;
                continue;
            }
        }

        float d = max(lenpxz - rr, rr - 0.2 - lenpxz);
        float dw2 = DOOR_WIDTH * 0.5;
        float ad = abs(lenpxz * sin(a));
        d = max(d, -min(max(ad - dw2, p.y - DOOR_HEIGHT + dw2),
            length(vec2(ad, p.y - DOOR_HEIGHT + dw2)) - dw2));
        d = min(d, max(roomRadius(n) - 0.2 - distance(p, vec3(0.0,DOOR_HEIGHT + 0.2,0.0)), DOOR_HEIGHT + 0.2 - p.y));
        d = min(d, max(max(max(p.y - STEP_HEIGHT, lenpxz - rr - 0.1),
            -max(-p.y, lenpxz - rr)),
            -(max(-STEP_HEIGHT-p.y, distance(vec2(0.0, -1.0) * centerDist(en, n), p.xz) - roomRadius(en)))));
        return SceneD(d,rdepth,n,ra,p);
    }
}

SceneD sceneSDF(vec3 e, vec3 p) {
    return roomSDF(e.xz, p, 0.0, timeDepth(), 8, roomDoorsByDepth(timeDepth()));
}

// ##################################################

vec3 colFromPoint(vec3 p, SceneD sd)
{
    float cd = length(sd.rp.xz);
    if (abs(sd.rp.y) <= EPSILON)
    {
        return vec3(
            (0.5 + float(sd.rn % 3) * 0.2) + 0.2 * (sin(cd * 53.0) * sin(sd.rp.x * 83.0) * sin(sd.rp.z * 37.0)),
            0.1,
            (0.5 + float((sd.rn + sd.rd) / 3 % 3) * 0.2) + 0.2 * (sin(cd * 59.0) * sin(sd.rp.x * 41.0) * sin(sd.rp.z * 79.0)));
    }
    else
    {
        vec3 rpm1 = vec3(0.5 * sd.rp.xyz + 5.0*mod(sd.rp.yzx, 0.1) * cos(31.9 * sd.rp.zxy));
        vec3 rpm2 = vec3(0.5 * sd.rp.xzy + 3.0*mod(sd.rp.zyx, 0.166) * cos(22.1 * sd.rp.yxz));
        return vec3(
            0.4 + 0.05 * (sin((rpm1.x + rpm1.z) * 71.0) + sin((rpm1.y + rpm1.x) * 87.0)),
            0.4 + 0.05 * (sin((rpm1.x + rpm2.z) * 71.0) + sin((rpm1.y + rpm1.x) * 87.0)),
            0.6 + 0.1 * (sin((rpm2.x + rpm2.z) * 93.0) + sin((rpm2.y + rpm2.x) * 117.0)));
    }
    return vec3(0.5);
}

// ##################################################

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */
SceneD shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        SceneD sd = sceneSDF(eye, eye + depth * marchingDirection);
        if (sd.d < EPSILON) {
            return SceneD(depth, sd.rd, sd.rn, sd.ra, sd.rp);
        }
        depth += sd.d;
        if (depth >= end) {
            break;
        }
    }
    return SceneD(end, MAX_ROOM_DEPTH + 1, 2, 0.0, vec3(0.0));
}
            

/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * gl_FragCoord.xy: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size * 0.5;
    float z = size.y / tan(radians(fieldOfView) * 0.5);
    return normalize(vec3(xy, -z));
}

/**
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 e, vec3 p) {
    return normalize(vec3(
        sceneSDF(e,vec3(p.x + EPSILON, p.y, p.z)).d - sceneSDF(e,vec3(p.x - EPSILON, p.y, p.z)).d,
        sceneSDF(e,vec3(p.x, p.y + EPSILON, p.z)).d - sceneSDF(e,vec3(p.x, p.y - EPSILON, p.z)).d,
        sceneSDF(e,vec3(p.x, p.y, p.z  + EPSILON)).d - sceneSDF(e,vec3(p.x, p.y, p.z - EPSILON)).d
    ));
}

/**
 * Lighting contribution of a single point light source via Phong illumination.
 * 
 * The vec3 returned is the RGB color of the light's contribution.
 *
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 * lightPos: the position of the light
 * lightIntensity: color/intensity of the light
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, float ra, vec3 rp, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(eye,p);
    vec3 rpr = vec3(rp.x * cos(ra) - rp.z * sin(ra), rp.y, rp.x * sin(ra) + rp.z * cos(ra));
    vec3 L = normalize(lightPos - rpr);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    }
    
    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

/**
 * Lighting via Phong illumination.
 * 
 * The vec3 returned is the RGB color of that point after lighting is applied.
 * k_a: Ambient color
 * k_d: Diffuse color
 * k_s: Specular color
 * alpha: Shininess coefficient
 * p: position of point being lit
 * eye: the position of the camera
 *
 * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
 */
vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, float ra, vec3 rp, vec3 eye) {
    const vec3 ambientLight = 0.8 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(0.0,
                          DOOR_HEIGHT + 0.1,
                          0.0);
    vec3 light1Intensity = vec3(0.9, 0.9, 1.0);
    
    color += phongContribForLight(k_d, k_s, alpha, p, ra, rp, eye,
                                  light1Pos,
                                  light1Intensity);
                                  
    return color;
}

/**
 * Return a transform matrix that will transform a ray from view space
 * to world coordinates, given the eye point, the camera target, and an up vector.
 *
 * This assumes that the center of the camera is aligned with the negative z axis in
 * view space when calculating the ray marching direction. See rayDirection.
 */
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

// ##################################################

void main(void)
{
    vec3 viewDir = rayDirection(90.0, resolution.xy);
    float t = 0.5 + 0.5 * sin(PI * time2() - 0.5 * PI);
    int doors = roomDoorsByDepth(timeDepth());
    float rr = roomRadius(doors);
    int ndoors = roomDoorsByDepth(timeDepth() + 1);
    float nrr = centerDist(doors, ndoors) - roomRadius(ndoors);
    float da = PI - nextDoorAngle();
    float h = 0.8 + 0.01 * abs(sin(time * 5.0)) + STEP_HEIGHT * time2();
    vec3 tcv = vec3(sin((PI - da) * t), 0.0, -cos((PI - da) * t));
    vec3 eye = mix(rr,nrr,time2()) * tcv * (1.0 - sqrt(1.0 - 4.0*(0.5-t)*(0.5-t))) + vec3(0.0, h, 0.0);
    vec3 eyeDir = normalize(vec3(sin(t * da), -0.1 + 0.10 * sin(2.0 * PI * time2()), cos(t * da)));
    
    mat4 viewToWorld = viewMatrix(eye, eye + eyeDir, vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    SceneD sd = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
    
    if (sd.d > MAX_DIST - EPSILON)
    {
        glFragColor = vec4(0.0);
    }
    else
    {
        vec3 p = eye + sd.d * worldDir;

        vec3 K_a = vec3(0.2, 0.2, 0.2);
        vec3 K_d = colFromPoint(p, sd);
        vec3 K_s = vec3(1.0, 1.0, 1.0);
        float shininess = 10.0;

        vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, sd.ra, sd.rp, eye);
        
        color = mix(color, vec3(0.0), sd.d / float(MAX_DIST));

        glFragColor = vec4(color, 1.0);
    }
}
