
require 'scraperwiki'
require 'open-uri'
require 'nokogiri'

def noko_xml(url)
  noko ||= Nokogiri::XML(open(url).read) 
  noko.remove_namespaces!
end
  
periods_xml = noko_xml('http://opendata.congreso.cl/wscamaradiputados.asmx/getPeriodosLegislativos')
periods_xml.xpath('//PeriodoLegislativo/ID').map { |id| id.text }.sort.reverse.each do |period_id|
  puts "Fetching term #{period_id}"
  deps = noko_xml "http://opendata.congreso.cl/wscamaradiputados.asmx/getDiputados_Periodo?prmPeriodoID=#{period_id}"
  deps.xpath('//Diputados/Diputado').each do |dep|
    person = { 
      id: dep.xpath('DIPID').text.strip,
      name: %w(Nombre Nombre2 Apellido_Paterno Apellido_Materno).map { |namepart|
        dep.xpath(namepart).text.strip
      }.delete_if(&:empty?).compact.join(" "),
      sort_name: dep.xpath('Apellido_Paterno').text.strip,
      gender: ['female', 'male'][dep.xpath('Sexo/@Codigo').text.strip.to_i],
      email: dep.xpath('Correo_Electronico').text.strip,
      district: dep.xpath("Ejercicios_Periodos_Legislativos/EjercicioPeriodoLegislativo[Periodo/ID='#{period_id}']/Distrito").text.strip,
      party: dep.xpath("Militancias_Periodos/Militancia[Periodo/ID='#{period_id}']/Partido").text.strip,
      party_id: dep.xpath("Militancias_Periodos/Militancia[Periodo/ID='#{period_id}']/Partido/@Codigo").text.strip,
      term: period_id,
    }
    ScraperWiki.save_sqlite([:id, :term], person)
  end
end
