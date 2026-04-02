#version 420

// original https://www.shadertoy.com/view/4lKfWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = radians(180.);
const float Infinity = 1e6;

//Камера
struct Camera {
    //Задаваемые параметры
    float fov;
    float aspect;
    vec3  origin;
    vec3  target;
    vec3  up;
    //Расчетные параметры
    float factor;
    vec3  forward;
    vec3  right;
    vec3  position;
    vec3  coord;
};

struct Material {
    vec3  ambientColor;
    float diffuse;
    float specular;
    float shininess;
    float mirror;
};
Material material_0 = Material(vec3(0.1, 0.1, 0.5), 0.6, 0.8, 16.0, 0.75);
Material material_1 = Material(vec3(0.1, 0.5, 0.1), 0.2, 0.4, 16.0, 0.5);

//Дополнительные параметры, возвращаемые картой расстояний
struct Mapdata {
    float   distance;    //Последнее приближение луча к элементу сцены (стремится к 0 в случае нахождения точки пересечения)
    int     id;            //id элемента сцены
    Material material;
};
//Луч
struct Ray {
    //Задаваемые параметры
    vec3  origin;        //Начало луча
    vec3  direction;    //Направление луча
    float near;            //Минимальное расстояние до элемента
    float far;            //Предельное расстояние до элемента
    float epsilon;        //Точность
    int      steps;        //Максимальное число итераций
    //Возвращаемые параметры
    float distance;     //Расстояние до точки элемента сцены от ray.origin в направлении ray.direction
    vec3  position;     //Текущая точка элемента сцены ray.origin + ray.direction * ray.distance
    bool  hit;            //Успех нахождения точки пересечения
    Mapdata mapdata;    //Дополнительные параметры, возвращаемые картой расстояний
};
//Формирование луча камеры
Ray lookAt (in vec2 uv, inout Camera cam) {
    //Расчетные характеристики камеры
    cam.factor         = 1.0/tan(radians(cam.fov/2.));
    cam.forward     = normalize(cam.target-cam.origin); 
    cam.right         = normalize(cross(cam.up, cam.forward));
    cam.up             = cross(cam.forward, cam.right);
    cam.position     = cam.origin + cam.factor * cam.forward;
    cam.coord         = cam.position + uv.x * cam.right * cam.aspect + uv.y * cam.up;
    //Формирование луча
    Ray ray;
    {
        ray.origin         = cam.origin;
        ray.direction     = normalize(cam.coord - cam.origin);
    }
    return ray;
}

struct Light {
    vec3 position;
    vec3 direction;
    vec3 color;
    float radius;
};
Light light = Light(vec3(1.5, 0.25, 0.0), vec3(0), vec3(1), 0.5);

const int COUNT = 12;
Light lights[COUNT];
//-------------Вспомогательные функции-----------------------------
//Масштаб вектора
void scale (inout vec3 v, vec3 s) {
    v = v * s;
}
//Перемещение вектора
void translate (inout vec3 v, vec3 delta) {
    v = v - delta;
}
//Вращение вектора
void rotate(inout vec3 v, vec3 rad) {
    vec3 c = cos(rad), s = sin(rad);
    if (rad.x!=0.) v = vec3(v.x,                    c.x * v.y + s.x * v.z, -s.x * v.y + c.x * v.z);
    if (rad.y!=0.) v = vec3(c.y * v.x - s.y * v.z, v.y,                    s.y * v.x + c.y * v.z);
    if (rad.z!=0.) v = vec3(c.z * v.x + s.z * v.y, -s.z * v.x + c.z * v.y, v.z                    );
}
//-------------------------------------------------------
float dSphere(vec3 p, float radius) {
    return length(p) - radius;
}
float dPlane( vec3 p, vec3 normal) {
    return dot(p, normal);
}
//----------------------------------------------
float map(vec3 p, out Mapdata mapdata){
    mapdata.distance = Infinity;
    float d;
    //Плоскость
    d = min(mapdata.distance , dPlane(p, vec3(0,1,0)));
    if (mapdata.distance > d) {
        mapdata.distance = d;
        mapdata.id = 0;
        mapdata.material = material_0;
    }
    
    //Сфера
    d = min(mapdata.distance , dSphere(p, 0.25));
    if (mapdata.distance > d) {
        mapdata.distance = d;
        mapdata.id = 1;
        mapdata.material = material_1;
    }

    return mapdata.distance;
}

//Карта расстояний до элементов сцены (без доп. параметров)
float map ( in vec3 p ) {
    Mapdata mapdata;
    return map (p, mapdata);
}
//Нормали в точке поверхности
vec3 mapNormal( in vec3 p, float epsilon ) {
    mat3 eps = mat3(epsilon);
    return normalize( vec3(
        map( p + eps[0]) - map(p - eps[0]),
        map( p + eps[1]) - map(p - eps[1]),
        map( p + eps[2]) - map(p - eps[2])
    ));
}
//Пересечение луча с элементами сцены
int rayMarch( inout Ray ray ) {
    //Минимальное расстояник
    ray.distance = ray.near;
    //Флаг пересечения            
    ray.hit = false;                    
    float d;
    for (int i = 0; i < 1024; ++i) {
        //Проверка ограничения итераций
        if (i==ray.steps) break;        
        //Текущая точка луча
        ray.position = ray.origin + ray.distance * ray.direction;    
        //Минимальное расстояние до элемента сцены
        d = map(ray.position, ray.mapdata);        
        //Проверка достижения требуемой точности
        if (d < ray.epsilon) {            
            ray.hit = true;
            return i;
        }
        //Перемещаем точку луча
        ray.distance += d;                
        //Проверка достижения предельной дистанции
        if (ray.distance > ray.far) {
            return i;
        }
    }
    return ray.steps;
}

vec3 diffuseLighting(in vec3 normal, Light light, Material material){
    float lambertian = max(dot(light.direction, normal), 0.0);
      return  lambertian * vec3(material.diffuse) * light.color; //colorDiffuse
}

vec3 specularLighting(in vec3 p, in vec3 normal, in vec3 camPos, Light light, Material material){
    //https://en.wikipedia.org/wiki/Specular_highlight#Cook.E2.80.93Torrance_model
    //https://renderman.pixar.com/view/cook-torrance-shader
    
    vec3 V = normalize(camPos - p);
    vec3 H = normalize(light.direction + V);
    
    float NdotH = dot(normal, H);
    float NdotV = dot(normal, V);
    float VdotH = dot(V, H);
    float NdotL = dot(normal , light.direction);
    
    float lambda  = 0.25;
    float F = pow(1.0 + NdotV, lambda);
    
    float G = min(1.0,min((2.0*NdotH*NdotV/VdotH), (2.0*NdotH*NdotL/VdotH)));
    
   // Beckmann distribution D
    float alpha = 5.0*acos(NdotH);
    float gaussConstant = 1.0;
    float D = gaussConstant*exp(-(alpha*alpha));
    
    float c = 1.0;
    float specular = c *(F*D*G)/(PI*NdotL*NdotV);
    
    return specular * vec3(material.specular) * light.color; //colorSpecular
}

vec3 lighting(in vec3 p, in vec3 normal, in vec3 camPos, in Light light, in Material material) {
    float lightDistance = length(light.position - p);
    
      vec3 color =  diffuseLighting(normal, light, material);
    color += specularLighting(p, normal, camPos, light, material);
    
    Ray ray;
    {
        ray.origin         = p;
        ray.direction     = light.direction;
        ray.near        = 0.01;
        ray.far          = lightDistance;
        ray.epsilon        = 0.001;
        ray.steps        = 96;
    }
    rayMarch(ray);
    
    if (ray.hit) {
        float shadow = clamp(ray.distance/ray.far, 0.0, 1.0);
        float  attenuation = 1.0 / (1.0 +  0.1 * lightDistance * lightDistance);
        color *= attenuation * shadow;
    }
    return  color;
}

vec3  drawLight(vec3 color, vec3 p, vec3 camPos, Light light){
    vec3 rayDirection = normalize(camPos - p);
    vec3 v = camPos - light.position;
    vec3 v_proj = dot(v, rayDirection) * rayDirection;
    float d = length(v - v_proj);
    
    if (d < light.radius){
           float a = 1.0 - d/light.radius;
           color =  mix(color, light.color, pow(a, 4.0));
    }
    return color;
}

void main(void)
{
    vec2 u_canvas = resolution.xy;
    float u_time = time;
    
    
    float aspect = u_canvas.x/u_canvas.y;
    vec2 uv = gl_FragCoord.xy / u_canvas.xy;
    uv = uv - 0.5;

    Camera cam;
    {
        cam.fov     = 50.;
        cam.aspect  = aspect;
        cam.origin     = vec3( 0.0, 2.5,-4.0);
        cam.target  = vec3( 0.0, 0.0, 0.0);
        cam.up         = vec3(0,1,0);
    }

    Ray ray = lookAt(uv, cam);
    {
        ray.near     = 0.0;
        ray.far      = 20.0;
        ray.epsilon = 0.001;
        ray.steps     = 64;
    }
    rayMarch(ray);

    vec3 color = vec3(0);

    if (ray.distance<ray.far) {
        vec3 normal = mapNormal(ray.position, ray.epsilon);

        vec3 col = ray.mapdata.material.ambientColor;

        for (int i=0; i<COUNT; i++) {
            lights[i] = light;
            float index = mod(float(i),6.);
            if ( index==0.) {
                lights[i].color = vec3(0.6, 0.1, 0.1);
            } else if (index==1.) {
                lights[i].color = vec3(0.1, 0.6, 0.1);
            } else if (index==2.) {
                lights[i].color = vec3(0.1, 0.1, 0.6);
            } else if (index==3.) {
                lights[i].color = vec3(0.6, 0.1, 0.6);
            } else if (index==4.) {
                lights[i].color = vec3(0.6, 0.6, 0.1);
            } else if (index==5.) {
                lights[i].color = vec3(0.1, 0.6, 0.6);
            }
            rotate(lights[i].position, vec3(0,1,0) * (0.6 + float(i)*0.2) * u_time);
            lights[i].direction = normalize(lights[i].position - ray.position);
            col += lighting(ray.position, normal, ray.origin, lights[i], ray.mapdata.material);
            //Цвет источников света
            color = drawLight(color, ray.position, ray.origin, lights[i]);
        }
        color += col*(1.0 - ray.mapdata.material.mirror);
    }

    //Гамма-коррекция
    float screenGamma = 2.2;
    color = pow(color, vec3(1.0/screenGamma));

    glFragColor = vec4(color, 1.0);
}
