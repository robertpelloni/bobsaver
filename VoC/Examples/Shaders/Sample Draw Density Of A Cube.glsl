#version 420

// original https://www.shadertoy.com/view/7t3GRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// #define multi

float PI=3.14;
const float epsilon = 0.001;  

struct Ray{
    vec3 from;
    vec3 dir;
};

vec3 toLocalPos(vec3 pos ,vec3 x,vec3 y, vec3 z,vec3 original){
    vec3 diff =pos -original;
    return vec3(dot(diff,x),dot(diff,y),dot(diff,z));
}

vec3 toLocalVec(vec3 dir ,vec3 x,vec3 y, vec3 z){
    return vec3(dot(dir,x),dot(dir,y),dot(dir,z));
}

float degreeToRad(float degree){
    return degree*PI/180.0;
}

float def_saturate(float v){
    return v<0.?0.:(v>1.0?1.:v);
}

bool hitPlane(in Ray ray,in vec3 plane_N,in vec3 plane_C,inout vec3 hit_pos)
{
    // ray hit plane 
    vec3 from =ray.from;
    vec3 dir = ray.dir;
    //(F-C)。N + t (D。N) = 0
    // t  = (C-F)。N / (D。N)
    // t  = (A / (B)
    float B = dot(dir, plane_N);
    float A = dot(plane_C- from, plane_N);

    // avoid divide by 0
    if (abs(B) < epsilon)
        return false;

    float t = A / B;
    hit_pos = from + t * dir;
    
    if(t>0.0)
        return true;
}

bool hitRect(in Ray ray,in vec3 plane_N,in vec3 plane_C,in vec3 plane_axis_x,float half_width,float half_height,inout vec3 hit_pos)
{
   
    // ray hit plane 
    vec3 from =ray.from;
    vec3 dir = ray.dir;
    //(F-C)。N + t (D。N) = 0
    // t  = (C-F)。N / (D。N)
    // t  = (A / (B)
    float B = dot(dir, plane_N);
    float A = dot(plane_C- from, plane_N);

    // avoid divide by 0
    if (abs(B) < epsilon)
        return false;

    float t = A / B;
    hit_pos = from + t * dir;

    // 檢查範圍
    vec3 planeAxisY = cross(plane_N,plane_axis_x);
    vec3 diff =hit_pos - plane_C;
    float x =dot(diff,plane_axis_x);
    float y = dot(diff,planeAxisY);

    if(t>0.0 && abs(x)<=half_width && abs(y)<=half_height){
        return true;
    }
    else 
        return false;
}

float myShape(vec3 pos){
    return 0.;  
}

// gradient is normal
vec3 getNormal(vec3 pos){
    float delta =0.01;
    vec3 temp=vec3(myShape(pos+vec3(delta,0.,0.))-myShape(pos),
                   myShape(pos+vec3(0.,delta,0.))-myShape(pos),
                   myShape(pos+vec3(0.,0.,delta))-myShape(pos)
                  );
    return normalize(temp);
}

float density_f(vec3 p){
    // return 1.;

    // move path
    float t =time;
    // p=p+vec3(cos(t),0.,sin(t))+t*vec3(0.,1.,0.);
    
    //remap range
    //p= 0.5*(p+vec3(1.));

    //scale range
    //p*=11.5;

    float freq=8.;
    float cube = abs(sin(freq*p.x)*sin(freq*p.y)*sin(freq*p.z));
    float cube2 = max(0.,sin(freq*p.y)*sin(freq*p.x)*sin(freq*p.z));

    freq=4.;
    float ball=abs(sin(freq*p.x)+sin(freq*p.y)-sin(freq*p.z))/3.;
    
    //pillar
    freq=4.5;
    float pillar=max(0.,sin(freq*p.x)*sin(freq*p.z));
    float pillar_solid =step(0.1,pillar);
    //return pillar;

    //return max(0.,ball);
    return max(0.,ball-cube2-pillar+cube);
    

    //return max(0.,sin(2.*p.y+t));
    //return dot(p,vec3(0.,1.,0.));
}

vec3 rainbowRamp(float v){
    
    v*=7.0;
    v = min(7., v);
    vec3 color[7];
    color[0]=vec3(1.,0.,0.);
    color[1]=vec3(1.,0.27,0.);
    color[2]=vec3(1.,1.,0.);
    color[3]=vec3(0.,1.,0.);
    color[4]=vec3(0.,1.,1.);
    color[5]=vec3(0.,0.,1.);
    color[6]=vec3(1.,0.,1.);
    int index =int(floor(v));
    return color[index];
}

vec3 shading(Ray ray,vec3 eye){
    // box 3 axis and origin
    vec3 box_origin=vec3(0.,0.,0.);
    vec3 y_axis =vec3(0.,1.,0.);
    float para_obj_rot=0.5*time;
    vec3 z_axis = vec3(-sin(para_obj_rot),0.,cos(para_obj_rot));
    vec3 x_axis =vec3(cos(para_obj_rot),0.,sin(para_obj_rot));

    // to local space
    Ray local_ray;
    local_ray.from =toLocalPos(ray.from,x_axis,y_axis,z_axis,box_origin);
    local_ray.dir=toLocalVec(ray.dir,x_axis,y_axis,z_axis);

    vec3 local_eye = toLocalPos(eye,x_axis,y_axis,z_axis,box_origin);

    // six side of box
    vec3 n[6];
    n[0]=vec3( 1.0, 0.0, 0.0 );
    n[1]=vec3( -1.0, 0.0, 0.0 );
    n[2]=vec3( 0.0, 1.0, 0.0 );
    n[3]=vec3( 0.0, -1.0, 0.0 );
    n[4]=vec3( 0.0, 0.0, 1.0 );
    n[5]=vec3( 0.0, 0.0, -1.0 );

    vec3 help_axis[6];
    help_axis[0]=vec3( 0.0, 0.0, 1.0 );
    help_axis[1]=vec3( 0.0, 0.0, 1.0 );
    help_axis[2]=vec3( 0.0, 0.0, 1.0 );
    help_axis[3]=vec3( 0.0, 0.0, 1.0 );
    help_axis[4]=vec3( 1.0, 0.0, 0.0 );
    help_axis[5]=vec3( 1.0, 0.0, 0.0 );
   
    vec3 color[6];
    color[0]=vec3( 1.0, 0.0, 0.0 );
    color[1]=vec3( 1.0, 0.0, 0.0 );
    color[2]=vec3( 0.0, 1.0, 0.0 );
    color[3]=vec3( 0.0, 1.0, 0.0 );
    color[4]=vec3( 0.0, 0.0, 1.0 );
    color[5]=vec3( 0.0, 0.0, 1.0 );

    vec3 shadingColor =vec3(0.,0.,0.);

    float near_hit=10000.;
    float far_hit=0.;
    vec3 near_p,far_p;
    bool is_hit_box=false;
    vec3 box_color;

    // Find 2 endpoints that pass through the box
    for(int i=0;i<6;++i){
        vec3 plane_N=n[i];
        vec3 plane_C=-plane_N;

        vec3 hit_pos;
        if(hitRect(local_ray,plane_N,plane_C,help_axis[i],1.0,1.0, hit_pos))
        {
            is_hit_box=true;

            float d =length(hit_pos-local_eye);
            if(d<near_hit){
                near_hit =d;
                near_p =hit_pos;
            }

            if(d>far_hit){
                far_hit=d;
                far_p=hit_pos;
            }

            if(dot(local_ray.dir,plane_N)>0.)
                continue;
                
            box_color=color[i];
        }
    }

    //test:check depth
    // if(is_hit_box){
    //     float depth=far_hit-near_hit; 
    //     float a =def_saturate(depth/2.82842712475);
    //     vec3 fog=vec3(0.75,.55,0.25);
    //     return vec3(a);
    //     // return mix(box_color,fog,a);
    // }

    const int max_it=20;
    if(is_hit_box){
        float depth=far_hit-near_hit; 
        vec3 dir = normalize(near_p-far_p);
        vec3 p=far_p;
        float diff =depth/float(max_it);
        vec3 value=vec3(0.);
        float count=0.;
        
        for(int i=0;i<max_it;++i){
            float d=density_f(p);
            
            //vec3 color =d*rainbowRamp(d);// use density to scale color
            vec3 color=d*vec3(0.89,0.65,0.41);

            float lower_opacity_factor=0.91;
            value =mix(value,color,lower_opacity_factor*d);
              
            p+= diff*dir;
        }

        
        return vec3(value);
    }
    
    return shadingColor;
}

Ray[4] createRayDiff(vec3 eye, vec3 xAxis,vec3 yAxis,vec3 p){
    vec2[4] multisampleDiff;
    float x = 0.5;
    float y =0.5;
    // offset from p
    multisampleDiff[0]=vec2(x,y)/resolution.y;   
    multisampleDiff[1]=vec2(-y,x)/resolution.y; 
    multisampleDiff[2]=vec2(-x,-y)/resolution.y;
    multisampleDiff[3]=vec2(y,-x)/resolution.y;

    Ray[4] rays;
    for(int i=0;i<4;++i){
        rays[i].from =p+( multisampleDiff[i].x*xAxis + multisampleDiff[i].y*yAxis );
        rays[i].dir =normalize(rays[i].from-eye);
    }

    return rays;
}

Ray createRay(vec3 eye, vec3 xAxis,vec3 yAxis,vec3 p){
    Ray ray;
    ray.from =p;
    ray.dir =normalize(ray.from-eye);

    return ray;
}

void main(void)
{
    // weight (from -1 to 1)
    vec2 weight = gl_FragCoord.xy/resolution.xy;
    weight= weight*2.0-1.0;
   

    vec3 lookAt =vec3(0.0,0.0,0.0);
    //vec3 eye = vec3(0.0,10.0,10.0);
    // vec3 eye = lookAt+ 7.0*vec3(cos(time),0.0,sin(time))+vec3(0.0,1.0,0.0);
    vec3 eye = lookAt+ vec3(0.,0.0,3.0);

    // camera 3 axis
    vec3 z_axis = normalize(eye-lookAt);
    vec3 y_axis = vec3(0.0,1.0,0.0);
    vec3 x_axis = cross(y_axis,z_axis);
    
    //near plane of view frustum (z = -1)
    float fovDegree =90.0;
    float halfFov = radians(0.5*fovDegree);
    float tanH = tan(halfFov);
    float tanW = tanH*resolution.x/resolution.y;

    // generate point from the plane
    vec3 pointOnNearZ = eye -z_axis + x_axis*weight.x*tanW + y_axis*weight.y*tanH;
    
    // disturb ray dir
    float A =0.025*sin(0.5*time);
    pointOnNearZ+=vec3(A*sin(10.*weight.y+5.*time),A*cos(10.*weight.x+5.*time),0.);
    

    vec3 color= vec3(0.0,0.0,0.0);
    #ifdef multi
        // Antialiasing
        Ray[4] ray =createRayDiff(eye,x_axis,y_axis,pointOnNearZ);
        for(int i=0;i<4;++i)
            color += shading(ray[i],eye);
        color *=0.25;
    #else
        Ray ray =createRay(eye,x_axis,y_axis,pointOnNearZ);
        color = shading(ray,eye);
    #endif

    glFragColor = vec4(color,1.0);
    // glFragColor=texture(iChannel0,weight);
}

