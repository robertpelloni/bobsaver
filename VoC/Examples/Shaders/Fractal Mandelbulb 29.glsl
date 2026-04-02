#version 420

// original https://www.shadertoy.com/view/Wsd3zB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float power = 8.;
const float zoomDetailRatio = .001;
const int maxIterations = 8;
const int maxSteps = 60;
const float antiAliasing = 2.;
const float sunSize = 1.0;
const float sunTightness = 16.0; // Probably has some physical name, the amount the sun "spreads"
const vec3 light = vec3(-0.707107, 0.000, 0.707107);

struct Ray
{
        vec3 origin;
        vec3 dir;
};

// Helper functions

        vec2 boundingSphere(vec4 sph, vec3 origin, vec3 ray)
        {
                vec3 oc = origin - sph.xyz;

                float b = dot(oc,ray);
                float c = dot(oc,oc) - sph.w*sph.w;
                float h = b*b - c;

                if( h<0.0 ) return vec2(-1.0);

                h = sqrt( h );

                return -b + vec2(-h,h);
        }

        void sphereFold(inout vec3 z, inout float dz, float r2, float innerRadius, float outerRadius)
        {
                if (r2 < innerRadius)
                {
                        // linear inner scaling
                        float temp = (outerRadius/innerRadius);
                        z *= temp;
                        dz*= temp;
                }
                else if (r2<outerRadius)
                {
                        // this is the actual sphere inversion
                        float temp =(outerRadius/r2);
                        z *= temp;
                        dz*= temp;
                }
        }

        void boxFold(inout vec3 w, float foldingLimit)
        {
                w = clamp(w, -foldingLimit, foldingLimit) * 2.0 - w;
        }

vec3 triplexPow(vec3 w, float power, inout float dw, float m)
{
        dw = (power * pow(sqrt(m), power - 1.)) * dw + 1.0;

        float r = length(w);
#if 1
        float theta = power * atan(w.x, w.z);
        float phi = power * acos(w.y / r);

        // Fun alternative: reverse sin and cos
        return pow(r, power) * vec3(sin(theta) * sin(phi), cos(phi), cos(theta) * sin(phi));
#else
        float theta = power * atan(w.y, w.x);
    float phi = power * asin(w.z / r);

        // Fun alternative: reverse sin and cos
        //return pow(r, power) * vec3(sin(theta) * sin(phi), cos(phi), cos(theta) * sin(phi));
        return pow(r, power) * vec3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi));
#endif
}

// Distance estimator

        float DistanceEstimator(vec3 w, out vec4 resColor, float Power)
        {
                vec3 c = w; float m = dot(w,w); vec4 trap = vec4(abs(w),m); float dw = 1.0;

                for(int i = 0; i < 8; i++)
                {
                        w = triplexPow(w, power, dw, m);w+=c;

                        m = dot(w,w);trap = min(trap, vec4(abs(w),m));

                        if (m > 2.) break;
                }

                resColor = vec4(m,trap.yzw);

                return abs(0.25* log(m)*sqrt(m)/dw);
        }

// Stuff like multiple distance estimators

        float sceneDistance(vec3 position, out vec4 resColor)
        {
                return DistanceEstimator(position, resColor, power);
        }

// The actual ray marching, implement things like bounding geometry

        float trace(Ray ray, out vec4 trapOut, float px, out float percentSteps)
        {
                float res = -1.0;

                vec4 trap;

                float t = 0.;
                int i = 0;
                for(; i<maxSteps; i++)
                {
                        vec3 pos = ray.origin + ray.dir * t;
                        float h = sceneDistance(pos, trap);
                        float th = 0.25 * px * t;

                        if(h<th || h > 5.)
                        {
                                break;
                        }
                        t += h;
                }

                percentSteps = float(i)/float(maxSteps);

                if (t < 5.)
                {
                        trapOut = trap;
                        res = t;
                }

                return res;
        }

        vec3 calculateNormal(vec3 p)
        {
                const vec3 small_step = vec3(0.001, 0.0, 0.0);

                vec3 gradient;
                vec4 temp;

                gradient.x = sceneDistance(p + small_step.xyy, temp) - sceneDistance(p - small_step.xyy, temp);
                gradient.y = sceneDistance(p + small_step.yxy, temp) - sceneDistance(p - small_step.yxy, temp);
                gradient.z = sceneDistance(p + small_step.yyx, temp) - sceneDistance(p - small_step.yyx, temp);

                return normalize(gradient);
        }

        float SoftShadow(Ray ray, float k)
        {
                float result = 1.0;
                float t = 0.0;

                vec4 temp;

                for(int i = 0; i < maxSteps; i++)
                {
                        float h = sceneDistance(ray.origin + ray.dir * t, temp);
                        result = min(result, k * h / t);

                        if(result < 0.001) break;

                        t += clamp(h, 0.01, 32.);
                }
                return clamp(result, 0.0, 1.0);
        }

// Transforming some inputs, calling trace and calculating color and shadow

        vec3 render(Ray ray, vec2 uv)
        {
                                vec3 sun = normalize(vec3(sin(time * 0.25),
                    abs(sin(time * 0.1)) * -1.,
                    cos(time * 0.25)));
            
                float px = (100./resolution.y) * 1. * 0.01;
                vec4 trap;
                float steps;

                float t = trace(ray, trap, px, steps);

                vec3 col = vec3(0);

                // Color the sky if we don't hit the fractal
                if(t < 0.0)
                {
                                    // Sky gradient

                    col += vec3(0.8, 0.95, 1.0) * (0.6 + 0.4 * ray.dir.y);

                                    // Sun

                    col += sunSize * vec3(0.8,0.7,0.5) * pow(clamp(dot(ray.dir, sun), 0.0, 1.0), sunTightness);

                    col += vec3(0.556, 0.843, 0.415) * steps * steps;

                }
                else
                {
                        col = vec3(0.01);col = mix(col, vec3(0.54,0.3,0.07), clamp(trap.y,0.0,1.0)); /*Inner*/col = mix(col, vec3(0.02,0.4,0.30), clamp(trap.z*trap.z,0.0,1.0));col = mix(col, vec3(0.15, 0.4, 0.04), clamp(pow(trap.w,6.0),0.0,1.0)); /*Stripes*/col *= 0.5;

                        // Lighting

                        // The end position of the ray
                        vec3 pos = (ray.origin + ray.dir * t);
                        vec3 normal = calculateNormal(pos);
                        Ray fractalToSun = Ray(pos + 0.001 * normal, sun);
                        vec3 fractalToSunDir = normalize(sun - ray.dir);
                        float occlusion = clamp(0.05*log(trap.x),0.0,1.0);
                        float fakeSSS = clamp(1.0+dot(ray.dir,normal),0.0,1.0);

                        // Sun
                        float shadow = SoftShadow(fractalToSun, 4.);
                        float diffuse = clamp(dot(sun, normal), 0.0, 1.0 ) * shadow;
                        float specular = pow(clamp(dot(normal,fractalToSunDir),0.0,1.0), 32.0 )*diffuse*(0.04+0.96*pow(clamp(1.0-dot(fractalToSunDir,sun),0.0,1.0),5.0));

                        // Bounce
                        float diffuse2 = clamp( 0.5 + 0.5*dot(light, normal), 0.0, 1.0 )*occlusion;

                        // Sky
                        float diffuse3 = (0.7+0.3*normal.y)*(0.2+0.8*occlusion);

                        vec3 light = vec3(0.0);
                        light += 7.0*vec3(1.50,1.10,0.70)*diffuse;
                        light += 4.0*vec3(0.25,0.20,0.15)*diffuse2;
                        light += 1.5*vec3(0.10,0.20,0.30)*diffuse3;
                        light += 2.5*vec3(0.35,0.30,0.25)*(0.05+0.95*occlusion); // ambient
                        light += 4.*fakeSSS*occlusion;                          // fake SSS

                        col *= light;
                        col = pow( col, vec3(0.7,0.9,1.0) );                  // fake SSS
                        col += specular * 15.;

                        // Reflection (?)
                        //vec3 reflection = reflect( ray.dir, normal );
                        //col += 8.0*vec3(0.8,0.9,1.0)*(0.2+0.8*occlusion)*(0.03+0.97*pow(fakeSSS,5.0))*smoothstep(0.0,0.1,reflection.y )*SoftShadow( Ray(pos+0.01*normal, reflection), 2.0 );
                }

                return col;
        }

void main(void)
{
        vec3 position = vec3(0.,0.,-1.6);
        vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;

        uv.x *= float(resolution.x) / float(resolution.y);

        vec3 direction = normalize(vec3(uv.xy, 1));

        vec3 col = render(Ray(position, direction), uv);

    glFragColor = vec4(col.xyz, 1.0);

}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 position, in vec3 direction )
{
            vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;

    glFragColor = vec4(render(Ray(position, direction), uv),1.);
}
