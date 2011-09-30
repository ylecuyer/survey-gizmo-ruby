module SurveyGizmoSpec
  # global model cleanup. Mostly stolen from DataMapper.
  def self.cleanup_models
   descendants = SurveyGizmo::Resource.descendants.to_a

   while model = descendants.shift
     model_name = model.name.to_s.strip

     unless model_name.empty? || model_name[0] == ?#
       parts         = model_name.split('::')
       constant_name = parts.pop.to_sym
       base          = parts.empty? ? Object : SurveyGizmoSpec.full_const_get(parts.join('::'))

       base.class_eval { remove_const(constant_name) if const_defined?(constant_name) }
     end

     model.instance_methods(false).each { |method| model.send(:undef_method, method) }

   end

   SurveyGizmo::Resource.descendants.clear
  end
  
end

class Object
  def full_const_get(name)
    list = name.split("::")
    list.shift if list.first.blank?
    obj = self
    list.each do |x|
      # This is required because const_get tries to look for constants in the
      # ancestor chain, but we only want constants that are HERE
      obj = obj.const_defined?(x) ? obj.const_get(x) : obj.const_missing(x)
    end
    obj
  end  
end