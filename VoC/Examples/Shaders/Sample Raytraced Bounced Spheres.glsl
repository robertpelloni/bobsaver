#version 420

// original https://www.shadertoy.com/view/3sfcRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//raytraced bounce shperes
//my first try create something on shadertoy
//twitter: @imod
//
//https://twitter.com/imod74

#define shpere_count 8
#define full_shpere_count 64
#define lights_count 3
#define max_intresections 8

#define PI  3.1415926535897932384626433832795
#define PI_half  1.57079632679489661923

float sinc(float x)
{
    return sin(x)/x;
}

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

struct material
{
    vec3 color;
    float highlight_intencity;
    float highlight_hard;
    float reflection;
    float refraction;
    float refraction_int;
    
};

material create_material(vec3 color, float highlight_intencity, float highlight_hard, float reflection, float refraction, float refraction_int)
{
    material new_material;
    new_material.color = color;
    new_material.highlight_intencity = highlight_intencity;
    new_material.highlight_hard = highlight_hard;
    new_material.reflection = reflection;
    new_material.refraction = refraction;
    new_material.refraction_int = refraction_int;
    
    return new_material;
}

struct ray
{
    vec3 position;
    vec3 dirrection;
};

struct sphere_shape
{
    vec3 position;
    float radius;
    material cur_material;
};

sphere_shape create_shpere(vec3 set_position, float set_radius, material set_material)
{
    sphere_shape new_sphere;
    new_sphere.position = set_position;
    new_sphere.radius = set_radius;
    new_sphere.cur_material = set_material;
    return new_sphere;
}

vec3 shpere_get_normal(sphere_shape shpere, vec3 position)
{
    return normalize(position - shpere.position);
}

vec3 ray_sphere_intersect(vec3 ray_start, vec3 ray_dir, sphere_shape cur_shpere)
{
    vec3 distance_point = (ray_dir * dot(ray_dir, cur_shpere.position - ray_start)) + ray_start;
    float distance_to_ray = length(cur_shpere.position - distance_point);
    
    if((distance_to_ray > cur_shpere.radius) || (dot(distance_point - ray_start, ray_dir) < 0.0))
    {
        return vec3(0,0,0);
    }

    float inner_line_length = sqrt((cur_shpere.radius*cur_shpere.radius) - (distance_to_ray*distance_to_ray));

    vec3 intersect_point = distance_point - (ray_dir * inner_line_length);

    return intersect_point;
}

struct light
{
    vec3 position;
    vec3 color;
    float intension;
    bool shadows;
};
    
    
light create_light(vec3 position, vec3 color, float intension, bool shadows)
{
    light new_light;
    new_light.position = position;
    new_light.color = color;
    new_light.intension = intension;
    new_light.shadows = shadows;
    return new_light;
}

struct camera
{
    vec3 position;
    vec3 rotation;
    float fov;
};

struct intresection
{
    vec3 position;
    vec3 normal;
    material cur_material;
    float distance_far;
};
    
vec3 ray_plane_intersect(vec3 ray_start, vec3 ray_dir)
{
    
  if ( ray_dir.z > 0.0)
  {
    return vec3(0,0,0);
  }

  float t = ((ray_start.x + ray_dir.x) - ray_start.x)/ray_dir.x;
  float intresection_x = ray_start.x - ((ray_start.z*ray_dir.x)/ray_dir.z);
  float intresection_y = ray_start.y - ((ray_start.z*ray_dir.y)/ray_dir.z);
  return vec3(intresection_x, intresection_y, 0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy - 0.5);
    uv.x = uv.x*(resolution.x/resolution.y);
    
    camera global_camera;
    global_camera.position = vec3(-15,0,5.5);
    global_camera.rotation = vec3(1,0,0);
    float new_time = sin(time*4.0+PI_half)*cos(2.0*time);
    float new_time2 = sin(time*2.0)*cos(8.0*time+PI_half);
    vec4 new_cam_rotation = rotationMatrix(vec3(0,0,1), new_time/128.0)*vec4(global_camera.rotation,1.0);
    new_cam_rotation = rotationMatrix(vec3(0,1,0), new_time2/128.0)*new_cam_rotation;
    global_camera.rotation = new_cam_rotation.xyz;
    //sin(x)*cos(2*x)
    global_camera.fov;
     
    material bacground_mat = create_material(vec3(0,0,0), 0.5, 100.0, 0.0, 0.0, 0.0);
    material test_mat = create_material(vec3(1,1,1), 0.5, 100.0, 0.0, 0.0, 0.0);
    
    //intresection prepare
    sphere_shape shapes_array[full_shpere_count];
    
    intresection base_intresection;
    base_intresection.distance_far = 999999999.0;
    base_intresection.cur_material = bacground_mat;
    base_intresection.position = vec3(1,0,0) * 100.0;
    base_intresection.normal = normalize(vec3(1,0,0));
    
    intresection intresection_array[max_intresections];
    for(int i=0;i<max_intresections;i++)
    {
        intresection_array[i] = base_intresection;

    }
    int current_intresection = 0;
    
    //lights create
    
    light lights_array[lights_count];
    lights_array[0] = create_light(vec3(sin(time)*15.0,cos(time)*15.0,20.0), vec3(0.5,0.75,1), 0.5, true);
    lights_array[1] = create_light(vec3(sin(time+PI)*15.0,cos(time+PI)*15.0,20.0), vec3(1,0.5,0.6), 0.5, true);
    lights_array[2] = create_light(vec3(0,0,200.0), vec3(0.8,0.8,1.0), 0.25, true);
    //lights_array[3] = create_light(vec3(-20,0,10), vec3(1.0,1.0,1.0), 0.5, false);
    
    //spheres create
    float circle_diameter = 2.5;
      float shpere_count_float = (PI*2.0)/float(shpere_count);
    circle_diameter = (cos(time*4.0) + cos(time*8.0 + PI/1.6) + cos(time*8.0 - PI/1.6))+3.0;
    
    float sphere_radius_din =  ((cos(time*4.0) + cos(time*8.0 + PI/1.6) + cos(time*8.0 - PI/1.6))+3.5)/4.5;
    
    
    for(int i=0;i<shpere_count;i++)
    {

        vec4 new_shpere_pos = vec4(sin(shpere_count_float*float(i))*circle_diameter,cos(shpere_count_float*float(i))*circle_diameter,0.0, 1.0);
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), cos(time))*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(0,1,0), time)*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(1,0,0), time)*new_shpere_pos;
        new_shpere_pos.z =new_shpere_pos.z + 5.0;
        
        shapes_array[i].position = new_shpere_pos.xyz;
        shapes_array[i].radius = sphere_radius_din;
        shapes_array[i].cur_material = test_mat;
        //vec3 new_shpere_pos = vec3(sin(PI*2.0),1,1);
        //local circle_position = math.vector3d.create(math.sin(((math.pi*2)/circle_shpere_count)*i)*circle_diameter, math.cos(((math.pi*2)/circle_shpere_count)*i)*circle_diameter, 0)
    }
    
    float circle_diameter_02 = 2.5;
      float shpere_count_float_02 = (PI*2.0)/float(shpere_count);
    circle_diameter_02 = ((cos(time*4.0 - 0.5) + cos(time*8.0 + PI/1.6 - 0.5) + cos(time*8.0 - PI/1.6 - 0.5))+3.0)/1.5;
    
    float sphere_radius_din_02 =  ((cos(time*4.0) + cos(time*8.0 + PI/1.6) + cos(time*8.0 - PI/1.6))+2.75)/4.5;
    
    
    for(int i=0;i<shpere_count;i++)
    {

        vec4 new_shpere_pos = vec4(sin(shpere_count_float_02*float(i) + PI/8.0)*circle_diameter_02,cos(shpere_count_float_02*float(i)+ PI/8.0)*circle_diameter_02,0.0, 1.0);
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), cos(time))*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(0,1,0), time)*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(1,0,0), time)*new_shpere_pos;
        new_shpere_pos.z =new_shpere_pos.z + 5.0;
        
        shapes_array[8+i].position = new_shpere_pos.xyz;
        shapes_array[8+i].radius = sphere_radius_din_02;
        shapes_array[8+i].cur_material = test_mat;
    }
    
    float circle_diameter_03 = 2.5;
      float shpere_count_float_03 = (PI*2.0)/float(shpere_count);
    circle_diameter_03 = ((cos(time*4.0 - 1.0) + cos(time*8.0 + PI/1.6 - 1.0) + cos(time*8.0 - PI/1.6 - 1.0))+2.5)/2.0;
    
    float sphere_radius_din_03 =  ((cos(time*4.0) + cos(time*8.0 + PI/1.6) + cos(time*8.0 - PI/1.6))+2.0)/5.0;
    
    
    for(int i=0;i<shpere_count;i++)
    {

        vec4 new_shpere_pos = vec4(sin(shpere_count_float_03*float(i))*circle_diameter_03,cos(shpere_count_float_03*float(i))*circle_diameter_03,0.0, 1.0);
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), cos(time))*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(0,1,0), time)*new_shpere_pos;
        new_shpere_pos = rotationMatrix(vec3(1,0,0), time)*new_shpere_pos;
        new_shpere_pos.z =new_shpere_pos.z + 5.0;
        
        shapes_array[16+i].position = new_shpere_pos.xyz;
        shapes_array[16+i].radius = sphere_radius_din_03;
        shapes_array[16+i].cur_material = test_mat;
    }
    
    
    float circle_diameter_04 = 18.0;
      float shpere_count_float_04 = (PI*2.0)/float(20);
    
    float sphere_radius_din_04 =  2.0;
    
    
    for(int i=0;i<20;i++)
    {

        vec4 new_shpere_pos = vec4(sin(shpere_count_float_04*float(i) + 0.0)*circle_diameter_04,cos(shpere_count_float_04*float(i) + 0.0)*circle_diameter_04,0.0, 1.0);
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), cos(time))*new_shpere_pos;
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), time)*new_shpere_pos;
        //new_shpere_pos = rotationMatrix(vec3(1,0,0), time)*new_shpere_pos;
        //new_shpere_pos.z =new_shpere_pos.z + 5.0 + cos(acos(new_shpere_pos.x/length(new_shpere_pos))*4.0 + time)*2.0 + (1.0/(5.0*cos(time*4.0)-6.0))*10.0 + 10.0;
        new_shpere_pos.z =new_shpere_pos.z + ((10.0/(5.0*cos(time*4.0 + sin(asin(new_shpere_pos.y/length(new_shpere_pos)))*5.0 )-7.0))+5.0)*4.0+1.0;
        //new_shpere_pos.z =new_shpere_pos.z + 5.0 + cos(time*2.0);
        
        shapes_array[24+i].position = new_shpere_pos.xyz;
        shapes_array[24+i].radius = sphere_radius_din_04;
        shapes_array[24+i].cur_material = test_mat;
    }
    
    float circle_diameter_05 = 55.0;
      float shpere_count_float_05 = (PI*2.0)/float(20);
    
    float sphere_radius_din_05 =  2.0;
    
    
    for(int i=0;i<20;i++)
    {

        vec4 new_shpere_pos = vec4(sin(shpere_count_float_05*float(i) + 0.0)*circle_diameter_05,cos(shpere_count_float_05*float(i) + 0.0)*circle_diameter_05,0.0, 1.0);
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), cos(time))*new_shpere_pos;
        //new_shpere_pos = rotationMatrix(vec3(0,1,0), time)*new_shpere_pos;
        //new_shpere_pos = rotationMatrix(vec3(1,0,0), time)*new_shpere_pos;
        //new_shpere_pos.z =new_shpere_pos.z + 5.0 + cos(acos(new_shpere_pos.x/length(new_shpere_pos))*4.0 + time)*2.0 + (1.0/(5.0*cos(time*4.0)-6.0))*10.0 + 10.0;
        new_shpere_pos.z =new_shpere_pos.z + ((10.0/(5.0*cos(time*4.0 + cos(acos(new_shpere_pos.x/length(new_shpere_pos)))*5.0 )-7.0))+5.0)*4.0+1.0;
        //new_shpere_pos.z =new_shpere_pos.z + 5.0 + cos(time*2.0);
        
        shapes_array[44+i].position = new_shpere_pos.xyz;
        shapes_array[44+i].radius = sphere_radius_din_05;
        shapes_array[44+i].cur_material = test_mat;
        shapes_array[44+i].cur_material.color = vec3(0.2,0.2,0.2);
    }
    

    vec3 ray_start = global_camera.position;
    vec4 ray_dir = rotationMatrix(vec3(0,0,1), uv.x)*vec4(global_camera.rotation,1.0);
    ray_dir = rotationMatrix(vec3(0,1,0), uv.y)*vec4(ray_dir);
    bool isIntersected = false;
    
    for(int i=0;i<full_shpere_count;i++)
    {
        vec3 cur_inter = ray_sphere_intersect(ray_start, ray_dir.xyz, shapes_array[i]);
        
        
        if(cur_inter != vec3(0,0,0))
        {
            isIntersected = true;
            current_intresection++;
            intresection_array[current_intresection].position = cur_inter;
            intresection_array[current_intresection].normal = shpere_get_normal(shapes_array[i], cur_inter); 
            intresection_array[current_intresection].cur_material = shapes_array[i].cur_material;
            intresection_array[current_intresection].distance_far = distance(global_camera.position, cur_inter);
        }
    }

    vec3 plane_intr_point = ray_plane_intersect(ray_start, ray_dir.xyz);
    if(plane_intr_point != vec3(0,0,0))
    {
        isIntersected = true;
        current_intresection++;
        intresection_array[current_intresection].position = plane_intr_point;
        intresection_array[current_intresection].normal = vec3(0,0,1); 
        intresection_array[current_intresection].cur_material = test_mat;
        intresection_array[current_intresection].distance_far = distance(global_camera.position, plane_intr_point);
    }

    //sort intersections
    bool isSorted = false;
    do 
    {
        isSorted = true;
        for(int i=0;i<max_intresections-1;i++)
        {
            if (intresection_array[i].distance_far > intresection_array[i+1].distance_far)
            {
                intresection intresection_tmp = intresection_array[i];
                intresection_array[i] = intresection_array[i+1];
                intresection_array[i+1] = intresection_tmp;
                isSorted = false;
            }
        }
    }
    while(!isSorted);
    
    
    vec3 col = vec3(0,0,0);
    
    if(isIntersected)
    {
        for(int i=0;i<lights_count;i++)
        {
            vec3 light_dir = normalize(lights_array[i].position - intresection_array[0].position);
            float light_intencity = dot(light_dir,intresection_array[0].normal);

            bool isShadow = false;

                for(int i=0;i<full_shpere_count;i++)
                {
                    vec3 cur_inter = ray_sphere_intersect(intresection_array[0].position + light_dir*0.01, light_dir, shapes_array[i]);
                    if(cur_inter != vec3(0,0,0))
                    {
                        isShadow = true;
                    }
                }

            if(!isShadow)
            {
                col = col + intresection_array[0].cur_material.color*light_intencity*lights_array[i].intension*lights_array[i].color;

                vec3 refl_vec = reflect(light_dir ,intresection_array[0].normal);
                float phong_highlight = dot(refl_vec, ray_dir.xyz);
                phong_highlight =  pow(clamp(phong_highlight, 0.0, 1.0),10.0)*0.5;
                col = col + phong_highlight;
            }
        }
    }
    col = clamp(col, vec3(0,0,0), vec3(1,1,1));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
